// Движки: ffmpeg (видео, звук), AVFoundation, документы, картинки.

import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import RenameConvert

@Suite(.enabled(if: TestEnv.hasFFmpeg), .timeLimit(.minutes(2)))
struct FFmpegEngineTests {
    init() { _ = TestEnv.ready }

    @Test func probeReadsDurationAndCodecs() async throws {
        let dir = try TempDir()
        let mkv = try await dir.ffmpeg("h.mkv", ["-f", "lavfi", "-i", "testsrc=d=1:s=320x240", "-f", "lavfi", "-i", "sine=d=1",
                                                 "-c:v", "hevc_videotoolbox", "-c:a", "libmp3lame"])
        let info = try await FFmpeg.probe(mkv)
        #expect(info.videoCodec == "hevc")
        #expect(info.audioCodecs == ["mp3"])
        #expect(abs((info.duration ?? 0) - 1) < 0.2)
    }

    @Test func autoCopiesHEVCWithQuickTimeTag() async throws {
        let dir = try TempDir()
        let mkv = try await dir.ffmpeg("h.mkv", ["-f", "lavfi", "-i", "testsrc=d=1:s=320x240", "-f", "lavfi", "-i", "sine=d=1",
                                                 "-c:v", "hevc_videotoolbox", "-c:a", "aac_at"])
        let mp4 = dir.file("out.mp4")
        try await FFmpegEngine.video(mkv, to: mp4, ext: "mp4", params: ConversionParams()) { _ in }
        let header = try await dir.describe(mp4)
        #expect(header.contains("Video: hevc"))
        #expect(header.contains("hvc1"))
    }

    @Test func autoReencodesCodecsQuickTimeCannotPlay() async throws {
        let dir = try TempDir()
        let avi = try await dir.ffmpeg("x.avi", ["-f", "lavfi", "-i", "testsrc=d=1:s=320x240", "-f", "lavfi", "-i", "sine=d=1",
                                                 "-c:v", "mpeg4", "-c:a", "libmp3lame"])
        let mp4 = dir.file("out.mp4")
        try await FFmpegEngine.video(avi, to: mp4, ext: "mp4", params: ConversionParams()) { _ in }
        let header = try await dir.describe(mp4)
        #expect(header.contains("Video: h264"))
        #expect(header.contains("Audio: aac"))
    }

    @Test func audioToMP3() async throws {
        let dir = try TempDir()
        let wav = try await dir.ffmpeg("a.wav", ["-f", "lavfi", "-i", "sine=d=1"])
        let mp3 = dir.file("a.mp3")
        try await FFmpegEngine.audio(wav, to: mp3, ext: "mp3", params: ConversionParams()) { _ in }
        #expect(try await dir.describe(mp3).contains("Audio: mp3"))
    }

    @Test func videoWithoutAudioReportsNoAudioTrack() async throws {
        let dir = try TempDir()
        let mkv = try await dir.ffmpeg("v.mkv", ["-f", "lavfi", "-i", "testsrc=d=1:s=160x120", "-c:v", "mpeg4"])
        await #expect(throws: ConvertError.self) {
            try await FFmpegEngine.audio(mkv, to: dir.file("a.mp3"), ext: "mp3", params: ConversionParams()) { _ in }
        }
    }
}

@Suite(.enabled(if: TestEnv.hasFFmpeg), .timeLimit(.minutes(2)))
struct MediaEngineTests {
    init() { _ = TestEnv.ready }

    /// Видео со стереошумом: на синусе AAC сжимает так сильно, что битрейт не видно.
    private func noisyMovie(in dir: TempDir) async throws -> URL {
        try await dir.ffmpeg("clip.mov", ["-f", "lavfi", "-i", "testsrc=d=3:s=320x240",
                                          "-f", "lavfi", "-i", "anoisesrc=d=3:sample_rate=48000:a=0.3",
                                          "-ac", "2", "-c:v", "h264_videotoolbox", "-c:a", "pcm_s16le"])
    }

    @Test func videoToFLACSkipsLossyIntermediate() async throws {
        let dir = try TempDir()
        let flac = dir.file("clip.flac")
        try await MediaEngine.extractAudio(try await noisyMovie(in: dir), to: flac, ext: "flac",
                                           params: ConversionParams(), workDir: dir.url) { _ in }
        #expect(try await dir.describe(flac).contains("Audio: flac"))
        #expect(!FileManager.default.fileExists(atPath: dir.file("audio.m4a").path))
    }

    @Test func videoToM4AUsesChosenBitrate() async throws {
        let dir = try TempDir()
        let movie = try await noisyMovie(in: dir)
        var sizes: [Int] = []
        for kbps in [128, 256] {
            var params = ConversionParams()
            params.audioBitrate = kbps
            let m4a = dir.file("clip-\(kbps).m4a")
            try await MediaEngine.extractAudio(movie, to: m4a, ext: "m4a", params: params, workDir: dir.url) { _ in }
            sizes.append(try FileManager.default.attributesOfItem(atPath: m4a.path)[.size] as? Int ?? 0)
        }
        #expect(sizes[1] > sizes[0] * 3 / 2)
    }

    @Test func gifToVideo() async throws {
        let dir = try TempDir()
        let gif = try await dir.ffmpeg("a.gif", ["-f", "lavfi", "-i", "testsrc=d=1:s=160x120:r=10"])
        let mp4 = dir.file("a.mp4")
        try await MediaEngine.gifToVideo(gif, to: mp4, ext: "mp4", params: ConversionParams()) { _ in }
        #expect(try await dir.describe(mp4).contains("Video: h264"))
    }

    @Test(.timeLimit(.minutes(1)))
    func onePixelWideGIFDoesNotHang() async throws {
        // Раньше при сбое записи цикл ожидания крутился вечно; теперь — результат или ошибка.
        let dir = try TempDir()
        let gif = try await dir.ffmpeg("tiny.gif", ["-f", "lavfi", "-i", "color=red:s=1x20:d=0.5:r=5"])
        _ = try? await MediaEngine.gifToVideo(gif, to: dir.file("tiny.mp4"), ext: "mp4", params: ConversionParams()) { _ in }
    }
}

@Suite struct DocumentEngineTests {
    init() { _ = TestEnv.ready }

    private func text(_ url: URL) throws -> String {
        try NSAttributedString(url: url, options: [:], documentAttributes: nil).string
    }

    @Test func cp1251TextIsDetected() async throws {
        let dir = try TempDir()
        let txt = try dir.write("cp.txt", "Привет, мир!".data(using: .windowsCP1251)!)
        let rtf = dir.file("cp.rtf")
        try await DocumentEngine.convert(txt, from: "txt", to: rtf, ext: "rtf", pageSize: PageSize.a4.points)
        #expect(try text(rtf).contains("Привет, мир!"))
    }

    @Test func htmlDeclaredCharsetIsRespected() async throws {
        let dir = try TempDir()
        let html = #"<html><head><meta charset="windows-1251"></head><body><p>Привет, мир!</p></body></html>"#
        let src = try dir.write("cp.html", html.data(using: .windowsCP1251)!)
        let out = dir.file("cp.txt")
        try await DocumentEngine.convert(src, from: "html", to: out, ext: "txt", pageSize: PageSize.a4.points)
        #expect(try String(contentsOf: out, encoding: .utf8).contains("Привет, мир!"))
    }

    @Test func htmlWithoutCharsetIsUTF8() async throws {
        let dir = try TempDir()
        let src = try dir.write("u.html", Data("<html><body><p>Привет, мир!</p></body></html>".utf8))
        let out = dir.file("u.txt")
        try await DocumentEngine.convert(src, from: "html", to: out, ext: "txt", pageSize: PageSize.a4.points)
        #expect(try String(contentsOf: out, encoding: .utf8).contains("Привет, мир!"))
    }

    @Test func longTextToMultiPagePDF() async throws {
        let dir = try TempDir()
        let src = try dir.write("long.txt", Data(String(repeating: "Строка текста для вёрстки.\n", count: 400).utf8))
        let pdf = dir.file("long.pdf")
        try await DocumentEngine.convert(src, from: "txt", to: pdf, ext: "pdf", pageSize: PageSize.a4.points)
        #expect((CGPDFDocument(pdf as CFURL)?.numberOfPages ?? 0) > 1)
    }
}

@Suite struct ImageEngineTests {
    init() { _ = TestEnv.ready }

    @Test func transparentPNGToJPEGIsFlattenedOnWhite() throws {
        let dir = try TempDir()
        let png = dir.file("t.png")
        let ctx = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        try ImageEngine.write(ctx.makeImage()!, to: png, type: .png, quality: 1)   // полностью прозрачная

        let jpg = dir.file("t.jpg")
        try ImageEngine.convert(png, to: jpg, type: .jpeg, quality: 0.9)
        #expect(ImageEngine.actualTypeID(of: jpg) == UTType.jpeg.identifier)
        let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(jpg as CFURL, nil)!, 0, nil)!
        #expect(averageColor(image).allSatisfy { $0 > 245 })   // белый, а не чёрный
    }

    /// Средний цвет картинки (RGB): рисуем её в один пиксель.
    private func averageColor(_ image: CGImage) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: 4)
        let ctx = CGContext(data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return Array(data.prefix(3))
    }
}
