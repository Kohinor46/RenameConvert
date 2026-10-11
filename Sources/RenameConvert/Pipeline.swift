// Общий конвейер: рабочая папка → движок → резервная копия → атомарная замена файла.

import Foundation

struct ConversionJob: Identifiable, Sendable {
    let id = UUID()
    /// Текущий путь файла (уже с новым расширением, но со старым содержимым).
    let path: String
    let oldName: String
    let plan: ConversionPlan
    var params: ConversionParams
    var keepOriginal: Bool

    var newName: String { (path as NSString).lastPathComponent }
    var directory: String { (path as NSString).deletingLastPathComponent }
}

enum Pipeline {
    /// Возвращает, где в Корзине лежит оригинал (если его сохраняли).
    static func run(_ job: ConversionJob, progress: @escaping ProgressHandler) async throws -> URL? {
        let fm = FileManager.default
        let fileURL = URL(fileURLWithPath: job.path)

        // Проверка доступа отдельно, чтобы отличить отказ TCC от битого файла.
        let fd = open(job.path, O_RDONLY)
        if fd >= 0 {
            close(fd)
        } else if errno == EPERM || errno == EACCES {
            throw ConvertError.noAccess(job.directory)
        }

        // Временная папка на том же томе — чтобы финальная замена была атомарной.
        let workDir = try fm.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: fileURL, create: true)
        defer { try? fm.removeItem(at: workDir) }

        // Движкам нужно правильное расширение у входного файла.
        let input = workDir.appendingPathComponent("input." + job.plan.from)
        if link(job.path, input.path) != 0 {
            try fm.copyItem(at: fileURL, to: input)
        }
        let output = workDir.appendingPathComponent("output." + job.plan.to)

        try await runEngine(job, input: input, output: output, workDir: workDir, progress: progress)
        try Task.checkCancellation()

        guard fm.fileExists(atPath: job.path) else { throw ConvertError.sourceGone }
        let trashed = job.keepOriginal ? backupToTrash(input, as: job.oldName, workDir: workDir) : nil

        if rename(output.path, job.path) != 0 {
            throw ConvertError.replaceFailed(String(cString: strerror(errno)))
        }
        return trashed
    }

    private static func runEngine(_ job: ConversionJob, input: URL, output: URL, workDir: URL,
                                  progress: @escaping ProgressHandler) async throws {
        let p = job.params, to = job.plan.to
        switch job.plan.engine {
        case .image:
            guard let type = Formats.imageTargetType(to) else { throw ConvertError.unsupported }
            try ImageEngine.convert(input, to: output, type: type, quality: p.imageQuality)
        case .pdfToImage:
            guard let type = Formats.imageTargetType(to) else { throw ConvertError.unsupported }
            try ImageEngine.renderPDFPage(input, to: output, type: type, quality: p.imageQuality)
        case .video:
            try await MediaEngine.convertVideo(input, to: output, ext: to, params: p, progress: progress)
        case .videoToGIF:
            try await MediaEngine.videoToGIF(input, to: output, params: p, progress: progress)
        case .videoToImage:
            guard let type = Formats.imageTargetType(to) else { throw ConvertError.unsupported }
            try await MediaEngine.videoFrame(input, to: output, type: type, quality: p.imageQuality)
        case .gifToVideo:
            try await MediaEngine.gifToVideo(input, to: output, ext: to, params: p, progress: progress)
        case .videoToAudio:
            try await MediaEngine.extractAudio(input, to: output, ext: to, params: p, workDir: workDir, progress: progress)
        case .audio:
            try await MediaEngine.convertAudio(input, to: output, ext: to, params: p)
        case .document:
            let from = job.plan.from
            try await MainActor.run {
                try DocumentEngine.convert(input, from: from, to: output, ext: to, pageSize: p.pdfPageSize.points)
            }
        case .data:
            try DataEngine.convert(input, from: job.plan.from, to: output, ext: to)
        case .archive:
            try await ArchiveEngine.convert(input, to: output, workDir: workDir)
        case .ffmpegVideo:
            try await FFmpegEngine.video(input, to: output, ext: to, params: p, progress: progress)
        case .ffmpegGIF:
            try await FFmpegEngine.gif(input, to: output, params: p, progress: progress)
        case .ffmpegAudio:
            try await FFmpegEngine.audio(input, to: output, ext: to, params: p, progress: progress)
        case .ffmpegFrame:
            guard let type = Formats.imageTargetType(to) else { throw ConvertError.unsupported }
            try await FFmpegEngine.frame(input, to: output, type: type, quality: p.imageQuality, workDir: workDir)
        case .ffmpegWebP:
            try await FFmpegEngine.webp(input, from: job.plan.from, to: output, quality: p.imageQuality, workDir: workDir)
        }
        guard FileManager.default.fileExists(atPath: output.path) else { throw ConvertError.encodeFailed }
    }

    /// Кладёт оригинал (жёсткая ссылка на исходные данные) в Корзину под старым именем.
    private static func backupToTrash(_ input: URL, as name: String, workDir: URL) -> URL? {
        let fm = FileManager.default
        let dir = workDir.appendingPathComponent("backup", isDirectory: true)
        let copy = dir.appendingPathComponent(name)
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            if link(input.path, copy.path) != 0 { try fm.copyItem(at: input, to: copy) }
            var result: NSURL?
            try fm.trashItem(at: copy, resultingItemURL: &result)
            return result as URL?
        } catch {
            Log.error("Резервная копия не создана: \(error)")
            return nil
        }
    }
}
