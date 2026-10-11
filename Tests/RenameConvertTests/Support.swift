// Общее для тестов: окружение (свой журнал, встроенный ffmpeg), временные папки, образцы файлов.

import Foundation
@testable import RenameConvert

enum TestEnv {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let ffmpegPath = repoRoot.appendingPathComponent("vendor/ffmpeg/ffmpeg").path

    /// Должно выполниться до первого обращения к `Log.url` и `FFmpeg.url` (они читают окружение один раз).
    /// Поэтому каждый набор тестов трогает его в `init`.
    static let ready: Bool = {
        let logs = FileManager.default.temporaryDirectory.appendingPathComponent("RenameConvertTests-\(getpid()).log")
        setenv("RC_LOG", logs.path, 1)
        if FileManager.default.isExecutableFile(atPath: ffmpegPath) { setenv("RC_FFMPEG", ffmpegPath, 1) }
        return true
    }()

    static var hasFFmpeg: Bool {
        _ = ready
        return FFmpeg.isAvailable
    }
}

/// Временная папка теста; удаляется в deinit.
final class TempDir {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("rc-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: url) }

    func file(_ name: String) -> URL { url.appendingPathComponent(name) }

    @discardableResult
    func write(_ name: String, _ data: Data) throws -> URL {
        let f = file(name)
        try data.write(to: f)
        return f
    }

    /// Создаёт файл встроенным ffmpeg: `ffmpeg <args> <name>`.
    @discardableResult
    func ffmpeg(_ name: String, _ args: [String]) async throws -> URL {
        let out = file(name)
        let result = try await Subprocess.run(URL(fileURLWithPath: TestEnv.ffmpegPath),
                                              ["-hide_banner", "-nostdin", "-loglevel", "error", "-y"] + args + [out.path])
        guard result.status == 0 else { throw ConvertError.toolFailed(result.stderr) }
        return out
    }

    /// Заголовок `ffmpeg -i` — кодеки и параметры потоков.
    func describe(_ url: URL) async throws -> String {
        try await Subprocess.run(URL(fileURLWithPath: TestEnv.ffmpegPath), ["-hide_banner", "-i", url.path]).stderr
    }
}
