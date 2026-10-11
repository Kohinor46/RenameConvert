// Видео и аудио: AVFoundation и системный afconvert.

import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

typealias ProgressHandler = @Sendable (Double) -> Void

enum MediaEngine {
    // MARK: Видео → видео

    static func convertVideo(_ input: URL, to output: URL, ext: String, params: ConversionParams,
                             progress: @escaping ProgressHandler) async throws {
        let asset = AVURLAsset(url: input)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw ConvertError.noVideoTrack }
        let fileType = videoFileType(ext)
        let needsComposition = params.videoResolution != .original || params.videoFPS != 0

        var preset: String
        switch params.videoCodec {
        case .hevc: preset = AVAssetExportPresetHEVCHighestQuality
        case .h264: preset = AVAssetExportPresetHighestQuality
        case .auto:
            // Смена контейнера без перекодирования — быстро и без потерь, если кодеки подходят.
            preset = AVAssetExportPresetPassthrough
            let compatible = await AVAssetExportSession.compatibility(ofExportPreset: preset, with: asset, outputFileType: fileType)
            if needsComposition || params.stripMetadata || !compatible { preset = AVAssetExportPresetHighestQuality }
        }

        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else { throw ConvertError.encodeFailed }
        if needsComposition {
            session.videoComposition = try await makeComposition(asset: asset, track: track, params: params)
        }
        if params.stripMetadata {
            session.metadataItemFilter = .forSharing()
        }
        session.shouldOptimizeForNetworkUse = fileType != .mov
        try await export(session, to: output, as: fileType, progress: progress)
    }

    private static func videoFileType(_ ext: String) -> AVFileType {
        switch ext {
        case "mp4": return .mp4
        case "m4v": return .m4v
        default: return .mov
        }
    }

    /// Масштабирование и частота кадров через композицию Core Image.
    private static func makeComposition(asset: AVAsset, track: AVAssetTrack,
                                        params: ConversionParams) async throws -> AVVideoComposition {
        let (natural, transform) = try await track.load(.naturalSize, .preferredTransform)
        let oriented = CGRect(origin: .zero, size: natural).applying(transform).size
        let w = abs(oriented.width), h = abs(oriented.height)

        var scale: CGFloat = 1
        if params.videoResolution != .original {
            scale = min(1, CGFloat(params.videoResolution.rawValue) / min(w, h))
        }
        let renderSize = CGSize(width: (w * scale / 2).rounded() * 2, height: (h * scale / 2).rounded() * 2)

        let composition = try await AVMutableVideoComposition.videoComposition(with: asset) { request in
            let image = request.sourceImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            request.finish(with: image, context: nil)
        }
        composition.renderSize = renderSize
        if params.videoFPS > 0 {
            // Иначе тайминг берётся из исходной дорожки и frameDuration игнорируется.
            composition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
            composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(params.videoFPS))
        }
        return composition
    }

    private static func export(_ session: AVAssetExportSession, to output: URL, as fileType: AVFileType,
                               progress: @escaping ProgressHandler) async throws {
        let monitor = Task {
            for await state in session.states(updateInterval: 0.25) {
                if case .exporting(let p) = state { progress(p.fractionCompleted) }
            }
        }
        defer { monitor.cancel() }
        try await session.export(to: output, as: fileType)
    }

    // MARK: Видео → GIF

    static func videoToGIF(_ input: URL, to output: URL, params: ConversionParams,
                           progress: @escaping ProgressHandler) async throws {
        let asset = AVURLAsset(url: input)
        guard try await !asset.loadTracks(withMediaType: .video).isEmpty else { throw ConvertError.noVideoTrack }
        let duration = try await asset.load(.duration).seconds
        let fps = Double(params.gifFPS)
        let count = max(1, min(Int(duration * fps), 1500))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let tolerance = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance
        if params.gifMaxWidth > 0 {
            generator.maximumSize = CGSize(width: params.gifMaxWidth, height: params.gifMaxWidth * 4)
        }

        guard let dst = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, count, nil) else {
            throw ConvertError.encodeFailed
        }
        CGImageDestinationSetProperties(dst, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps,
                                                          kCGImagePropertyGIFUnclampedDelayTime: 1 / fps]] as CFDictionary

        let times = (0..<count).map { CMTime(seconds: Double($0) / fps, preferredTimescale: 600) }
        var added = 0
        var previous: CGImage?
        for await result in generator.images(for: times) {
            try Task.checkCancellation()
            // Если кадр не достался — повторяем предыдущий, чтобы не сбить тайминг.
            if let image = (try? result.image) ?? previous {
                CGImageDestinationAddImage(dst, image, frameProps)
                previous = image
                added += 1
            }
            progress(Double(added) / Double(count))
        }
        guard added == count, CGImageDestinationFinalize(dst) else { throw ConvertError.encodeFailed }
    }

    // MARK: Видео → кадр

    static func videoFrame(_ input: URL, to output: URL, type: UTType, quality: Double) async throws {
        let asset = AVURLAsset(url: input)
        guard try await !asset.loadTracks(withMediaType: .video).isEmpty else { throw ConvertError.noVideoTrack }
        let duration = try await asset.load(.duration).seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let (image, _) = try await generator.image(at: CMTime(seconds: min(1, duration / 2), preferredTimescale: 600))
        try ImageEngine.write(image, to: output, type: type, quality: quality)
    }

    // MARK: GIF → видео

    static func gifToVideo(_ input: URL, to output: URL, ext: String, params: ConversionParams,
                           progress: @escaping ProgressHandler) async throws {
        guard let src = CGImageSourceCreateWithURL(input as CFURL, nil), CGImageSourceGetCount(src) > 0,
              let first = CGImageSourceCreateImageAtIndex(src, 0, nil) else { throw ConvertError.unreadable }
        let count = CGImageSourceGetCount(src)
        let width = first.width / 2 * 2, height = first.height / 2 * 2

        let writer = try AVAssetWriter(outputURL: output, fileType: videoFileType(ext))
        let codec: AVVideoCodecType = params.videoCodec == .hevc ? .hevc : .h264
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: codec, AVVideoWidthKey: width, AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
        ])
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ConvertError.encodeFailed }
        writer.startSession(atSourceTime: .zero)

        var time = 0.0
        for i in 0..<count {
            try Task.checkCancellation()
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
            guard let frame = CGImageSourceCreateImageAtIndex(src, i, nil),
                  let buffer = pixelBuffer(from: frame, pool: adaptor.pixelBufferPool, width: width, height: height) else { continue }
            adaptor.append(buffer, withPresentationTime: CMTime(seconds: time, preferredTimescale: 600))
            time += gifDelay(src, at: i)
            progress(Double(i + 1) / Double(count))
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: time, preferredTimescale: 600))
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? ConvertError.encodeFailed }
    }

    private static func gifDelay(_ src: CGImageSource, at index: Int) -> Double {
        let props = CGImageSourceCopyPropertiesAtIndex(src, index, nil) as? [CFString: Any]
        let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double) ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
        return delay < 0.02 ? 0.1 : delay   // так же поступают браузеры
    }

    private static func pixelBuffer(from image: CGImage, pool: CVPixelBufferPool?, width: Int, height: Int) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        if let pool { CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) }
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))   // прозрачность GIF → белый
        ctx.fill(rect)
        ctx.draw(image, in: rect)
        return buffer
    }

    // MARK: Видео → аудио

    static func extractAudio(_ input: URL, to output: URL, ext: String, params: ConversionParams,
                             workDir: URL, progress: @escaping ProgressHandler) async throws {
        let asset = AVURLAsset(url: input)
        guard try await !asset.loadTracks(withMediaType: .audio).isEmpty else { throw ConvertError.noAudioTrack }
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ConvertError.encodeFailed
        }
        if ext == "m4a" {
            try await export(session, to: output, as: .m4a, progress: progress)
        } else {
            let m4a = workDir.appendingPathComponent("audio.m4a")
            try await export(session, to: m4a, as: .m4a) { progress($0 * 0.7) }
            try await convertAudio(m4a, to: output, ext: ext, params: params)
        }
    }

    // MARK: Аудио → аудио

    static func convertAudio(_ input: URL, to output: URL, ext: String, params: ConversionParams) async throws {
        if ext == "m4a" {
            let aac = ["-f", "m4af", "-d", "aac"]
            do {
                try await Shell.run("/usr/bin/afconvert", aac + ["-b", String(params.audioBitrate * 1000), input.path, output.path])
            } catch {
                // Для моно или низкой частоты дискретизации высокий битрейт недопустим — берём стандартный.
                try await Shell.run("/usr/bin/afconvert", aac + [input.path, output.path])
            }
            return
        }
        let format: [String]
        switch ext {
        case "wav": format = ["-f", "WAVE", "-d", "LEI16"]
        case "aiff", "aif": format = ["-f", "AIFF", "-d", "BEI16"]
        case "caf": format = ["-f", "caff", "-d", "LEI16"]
        case "flac": format = ["-f", "flac", "-d", "flac"]
        default: throw ConvertError.unsupported
        }
        try await Shell.run("/usr/bin/afconvert", format + [input.path, output.path])
    }
}
