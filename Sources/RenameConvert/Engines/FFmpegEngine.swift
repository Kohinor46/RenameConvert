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
    static func run(_ args: [String], input: URL, progress: ProgressHandler? = nil) async throws {
        guard let url else { throw ConvertError.unsupported }
        let duration = progress == nil ? nil : try? await probeDuration(input)

        let process = Process()
        process.executableURL = url
        process.arguments = ["-hide_banner", "-nostdin", "-y", "-loglevel", "error", "-progress", "pipe:1", "-nostats"] + args
        let stdout = Pipe(), stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        if let progress, let duration, duration > 0 {
            stdout.fileHandleForReading.readabilityHandler = { handle in
                let text = String(decoding: handle.availableData, as: UTF8.self)
                for line in text.split(separator: "\n") where line.hasPrefix("out_time_us=") {
                    if let us = Double(line.dropFirst("out_time_us=".count)) {
                        progress(min(1, max(0, us / 1_000_000 / duration)))
                    }
                }
            }
        }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                process.terminationHandler = { p in
                    stdout.fileHandleForReading.readabilityHandler = nil
                    let message = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if p.terminationReason == .uncaughtSignal {
                        cont.resume(throwing: CancellationError())
                    } else if p.terminationStatus == 0 {
                        cont.resume()
                    } else {
                        Log.error("ffmpeg \(args.joined(separator: " ")): \(message)")
                        cont.resume(throwing: ConvertError.toolFailed(message.split(separator: "\n").last.map(String.init) ?? ""))
                    }
                }
                do { try process.run() } catch { cont.resume(throwing: error) }
            }
        } onCancel: {
            process.terminate()
        }
    }

    /// Длительность из заголовка `ffmpeg -i` («Duration: 00:01:02.50»).
    static func probeDuration(_ input: URL) async throws -> Double? {
        guard let url else { return nil }
        let process = Process()
        process.executableURL = url
        process.arguments = ["-hide_banner", "-nostdin", "-i", input.path]
        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        let text = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard let range = text.range(of: #"Duration: (\d+):(\d+):(\d+(?:\.\d+)?)"#, options: .regularExpression) else { return nil }
        let parts = text[range].dropFirst("Duration: ".count).split(separator: ":").compactMap { Double($0) }
        guard parts.count == 3 else { return nil }
        return parts[0] * 3600 + parts[1] * 60 + parts[2]
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

        // «Авто» без фильтров: сначала пробуем переупаковать без перекодирования.
        if params.videoCodec == .auto, filters.isEmpty {
            do {
                try await FFmpeg.run(common + ["-c", "copy", output.path], input: input, progress: progress)
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
            try await FFmpeg.run(args, input: input, progress: progress)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Постоянное качество (-q:v) поддерживают не все Mac — повторяем с битрейтом.
            try? FileManager.default.removeItem(at: output)
            let bitrate = args.firstIndex(of: "-q:v").map { i -> [String] in
                var a = args; a.replaceSubrange(i...(i + 1), with: ["-b:v", hevc ? "5M" : "8M"]); return a
            } ?? args
            try await FFmpeg.run(bitrate, input: input, progress: progress)
        }
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
        let duration = (try? await FFmpeg.probeDuration(input)) ?? 0
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
