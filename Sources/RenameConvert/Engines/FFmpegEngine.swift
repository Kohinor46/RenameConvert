// Встроенный ffmpeg: форматы, которые не умеет macOS (WebP, MP3, MKV, AVI, WebM, OGG…).

import Foundation
import UniformTypeIdentifiers

enum FFmpeg {
    /// Путь к ffmpeg внутри приложения (Contents/Helpers/ffmpeg) или из RC_FFMPEG — для тестов.
    static let url: URL? = {
        if let env = ProcessInfo.processInfo.environment["RC_FFMPEG"], FileManager.default.isExecutableFile(atPath: env) {
            return URL(fileURLWithPath: env)
        }
        let bundled = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/ffmpeg")
        return FileManager.default.isExecutableFile(atPath: bundled.path) ? bundled : nil
    }()

    static var isAvailable: Bool { url != nil }

    /// Запускает ffmpeg; прогресс считается по out_time из `-progress`.
    /// `duration` — если длительность уже известна, файл второй раз не разбирается.
    static func run(_ args: [String], input: URL, duration: Double? = nil, progress: ProgressHandler? = nil) async throws {
        guard let url else { throw ConvertError.unsupported }
        var duration = duration
        if progress != nil, duration == nil { duration = (try? await probe(input))?.duration }
        var full = ["-hide_banner", "-nostdin", "-y", "-loglevel", "error", "-nostats"]
        if progress != nil { full += ["-progress", "pipe:1"] }

        let lines = LineSplitter { line in
            guard let progress, let duration, duration > 0, line.hasPrefix("out_time_us="),
                  let us = Double(line.dropFirst("out_time_us=".count)) else { return }
            progress(min(1, max(0, us / 1_000_000 / duration)))
        }
        let result = try await Subprocess.run(url, full + args) { lines.feed($0) }
        try Task.checkCancellation()
        guard result.status == 0, !result.crashed else {
            Log.error("ffmpeg \(args.joined(separator: " ")): \(result.crashed ? "аварийное завершение" : result.stderr)")
            throw ConvertError.toolFailed(result.stderr.split(separator: "\n").last.map(String.init) ?? "")
        }
    }

    struct MediaInfo {
        var duration: Double?
        var videoCodec: String?
        var audioCodecs: [String] = []
    }

    /// Длительность и кодеки из заголовка `ffmpeg -i` («Duration: 00:01:02.50», «Stream #0:0: Video: hevc …»).
    static func probe(_ input: URL) async throws -> MediaInfo {
        guard let url else { return MediaInfo() }
        let text = try await Subprocess.run(url, ["-hide_banner", "-nostdin", "-i", input.path]).stderr
        var info = MediaInfo()
        if let range = text.range(of: #"Duration: (\d+):(\d+):(\d+(?:\.\d+)?)"#, options: .regularExpression) {
            let parts = text[range].dropFirst("Duration: ".count).split(separator: ":").compactMap { Double($0) }
            if parts.count == 3 { info.duration = parts[0] * 3600 + parts[1] * 60 + parts[2] }
        }
        for line in text.split(separator: "\n") where line.contains("Stream #") {
            for kind in ["Video", "Audio"] {
                guard let r = line.range(of: ": \(kind): ") else { continue }
                let codec = String(line[r.upperBound...].prefix { $0.isLetter || $0.isNumber || $0 == "_" })
                if kind == "Video" { info.videoCodec = info.videoCodec ?? codec } else { info.audioCodecs.append(codec) }
            }
        }
        return info
    }
}

/// Собирает строки из кусков вывода (кусок может оборваться посреди строки).
private final class LineSplitter: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private let onLine: (Substring) -> Void

    init(_ onLine: @escaping (Substring) -> Void) { self.onLine = onLine }

    func feed(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append(chunk)
        while let i = buffer.firstIndex(of: UInt8(ascii: "\n")) {
            let line = String(decoding: buffer[buffer.startIndex..<i], as: UTF8.self)
            buffer.removeSubrange(buffer.startIndex...i)
            onLine(Substring(line))
        }
    }
}

enum FFmpegEngine {
    // MARK: Видео → видео

    static func video(_ input: URL, to output: URL, ext: String, params: ConversionParams,
                      progress: @escaping ProgressHandler) async throws {
        var filters: [String] = []
        if params.videoResolution != .original {
            // Меньшая сторона не больше выбранной, без увеличения; размеры чётные.
            let r = params.videoResolution.rawValue
            filters.append("scale='if(gt(iw,ih),-2,min(\(r),iw))':'if(gt(iw,ih),min(\(r),ih),-2)'")
        }
        if params.videoFPS > 0 { filters.append("fps=\(params.videoFPS)") }
        var common = ["-i", input.path, "-map", "0:v:0", "-map", "0:a?"]
        if params.stripMetadata { common += ["-map_metadata", "-1"] }
        if ext != "mkv" { common += ["-movflags", "+faststart"] }

        // «Авто» без фильтров: переупаковываем без перекодирования, но только если результат
        // откроют QuickTime и iOS — иначе ffmpeg охотно положит в MP4 и VP9, и Opus.
        let info = try await FFmpeg.probe(input)
        if params.videoCodec == .auto, filters.isEmpty, ext == "mkv" || isQuickTimeCompatible(info, ext: ext) {
            var copy = common + ["-c", "copy"]
            if info.videoCodec == "hevc", ext != "mkv" { copy += ["-tag:v", "hvc1"] }
            do {
                try await FFmpeg.run(copy + [output.path], input: input, duration: info.duration, progress: progress)
                return
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try? FileManager.default.removeItem(at: output)
            }
        }

        let hevc = params.videoCodec == .hevc
        var args = common
        if !filters.isEmpty { args += ["-vf", filters.joined(separator: ",")] }
        args += ["-c:v", hevc ? "hevc_videotoolbox" : "h264_videotoolbox", "-q:v", "65", "-allow_sw", "1"]
        if hevc, ext != "mkv" { args += ["-tag:v", "hvc1"] }   // чтобы QuickTime и iOS открывали HEVC
        args += ["-c:a", "aac_at", "-b:a", "192k", output.path]
        do {
            try await FFmpeg.run(args, input: input, duration: info.duration, progress: progress)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Постоянное качество (-q:v) поддерживают не все Mac — повторяем с битрейтом.
            try? FileManager.default.removeItem(at: output)
            let bitrate = args.firstIndex(of: "-q:v").map { i -> [String] in
                var a = args; a.replaceSubrange(i...(i + 1), with: ["-b:v", hevc ? "5M" : "8M"]); return a
            } ?? args
            try await FFmpeg.run(bitrate, input: input, duration: info.duration, progress: progress)
        }
    }

    /// Кодеки, которые QuickTime и iOS воспроизводят из MOV/MP4/M4V.
    private static let quickTimeVideo: Set = ["h264", "hevc"]
    private static let quickTimeAudio: Set = ["aac", "alac", "mp3", "ac3", "eac3"]
    private static let movOnlyAudio: Set = ["pcm_s16le", "pcm_s16be", "pcm_s24le", "pcm_s24be", "pcm_f32le", "pcm_f32be"]

    private static func isQuickTimeCompatible(_ info: FFmpeg.MediaInfo, ext: String) -> Bool {
        guard let video = info.videoCodec, quickTimeVideo.contains(video) else { return false }
        let audio = ext == "mov" ? quickTimeAudio.union(movOnlyAudio) : quickTimeAudio
        return info.audioCodecs.allSatisfy(audio.contains)
    }

    // MARK: Видео → GIF (с подбором палитры — заметно лучше, чем без неё)

    static func gif(_ input: URL, to output: URL, params: ConversionParams, progress: @escaping ProgressHandler) async throws {
        let width = params.gifMaxWidth > 0 ? "'min(\(params.gifMaxWidth),iw)'" : "iw"
        let filter = "fps=\(params.gifFPS),scale=\(width):-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4"
        try await FFmpeg.run(["-i", input.path, "-filter_complex", filter, "-loop", "0", output.path], input: input, progress: progress)
    }

    // MARK: → аудио

    static func audio(_ input: URL, to output: URL, ext: String, params: ConversionParams,
                      progress: @escaping ProgressHandler) async throws {
        let codec: [String]
        switch ext {
        case "mp3": codec = ["-c:a", "libmp3lame", "-b:a", "\(params.audioBitrate)k"]
        case "m4a": codec = ["-c:a", "aac_at", "-b:a", "\(params.audioBitrate)k"]
        case "wav": codec = ["-c:a", "pcm_s16le"]
        case "aiff", "aif": codec = ["-c:a", "pcm_s16be"]
        case "caf": codec = ["-c:a", "pcm_s16le"]
        case "flac": codec = ["-c:a", "flac"]
        default: throw ConvertError.unsupported
        }
        var args = ["-i", input.path, "-vn", "-map", "0:a:0"] + codec
        if params.stripMetadata { args += ["-map_metadata", "-1"] }
        do {
            try await FFmpeg.run(args + [output.path], input: input, progress: progress)
        } catch ConvertError.toolFailed(let message) where message.localizedCaseInsensitiveContains("matches no streams") {
            throw ConvertError.noAudioTrack
        }
    }

    // MARK: Видео → кадр

    static func frame(_ input: URL, to output: URL, type: UTType, quality: Double, workDir: URL) async throws {
        let png = workDir.appendingPathComponent("frame.png")
        let duration = (try? await FFmpeg.probe(input))?.duration ?? 0
        try await FFmpeg.run(["-ss", String(min(1, duration / 2)), "-i", input.path, "-frames:v", "1", png.path], input: input)
        if type == .png {
            try FileManager.default.moveItem(at: png, to: output)
        } else {
            try ImageEngine.convert(png, to: output, type: type, quality: quality)
        }
    }

    // MARK: → WebP

    static func webp(_ input: URL, from: String, to output: URL, quality: Double, workDir: URL) async throws {
        var source = input
        // ffmpeg не читает HEIC/RAW и т.п. — сначала переводим в PNG средствами macOS.
        if !["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp"].contains(from) {
            source = workDir.appendingPathComponent("source.png")
            try ImageEngine.convert(input, to: source, type: .png, quality: 1)
        }
        let animated = from == "gif"
        var args = ["-i", source.path, "-c:v", animated ? "libwebp_anim" : "libwebp", "-quality", String(Int(quality * 100))]
        if animated { args += ["-loop", "0"] } else { args += ["-frames:v", "1"] }
        try await FFmpeg.run(args + [output.path], input: source)
    }
}
