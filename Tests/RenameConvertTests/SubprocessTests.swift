// Запуск внешних программ: большой вывод, отмена до запуска и во время работы.

import Foundation
import Testing
@testable import RenameConvert

@Suite struct SubprocessTests {
    init() { _ = TestEnv.ready }

    @Test(.timeLimit(.minutes(1)))
    func largeOutputDoesNotBlock() async throws {
        // Больше буфера канала (~64 КБ) и в stdout, и в stderr: раньше процесс здесь вставал навсегда.
        let script = "head -c 3000000 /dev/zero | tr '\\0' x; head -c 3000000 /dev/zero | tr '\\0' y >&2"
        let received = Counter()
        let result = try await Subprocess.run(URL(fileURLWithPath: "/bin/sh"), ["-c", script]) { received.add($0.count) }
        #expect(result.status == 0)
        #expect(received.value == 3_000_000)
        #expect(result.stderr.count == 1 << 20)   // stderr храним не больше 1 МБ
    }

    @Test func failureCarriesStderr() async throws {
        await #expect(throws: ConvertError.self) {
            try await Shell.run("/bin/sh", ["-c", "echo boom >&2; exit 3"])
        }
        let result = try await Subprocess.run(URL(fileURLWithPath: "/bin/sh"), ["-c", "echo boom >&2; exit 3"])
        #expect(result.status == 3 && result.stderr == "boom" && !result.crashed)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelBeforeLaunchDoesNotCrash() async throws {
        let start = Date()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await Shell.run("/bin/sleep", ["5"])
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(Date().timeIntervalSince(start) < 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelStopsRunningProcess() async throws {
        let start = Date()
        let task = Task { try await Shell.run("/bin/sleep", ["30"]) }
        try await Task.sleep(for: .milliseconds(300))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(Date().timeIntervalSince(start) < 3)
    }

    @Test(.enabled(if: TestEnv.hasFFmpeg), .timeLimit(.minutes(1)))
    func cancelStopsFFmpegThatIgnoresSIGTERM() async throws {
        // С -re и lavfi ffmpeg откладывает выход по SIGTERM почти на 30 с — нужен SIGKILL через 2 с.
        let dir = try TempDir()
        let start = Date()
        let task = Task {
            try await FFmpeg.run(["-re", "-f", "lavfi", "-i", "testsrc=d=30", "-f", "null", "-"], input: dir.url) { _ in }
        }
        try await Task.sleep(for: .milliseconds(500))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(Date().timeIntervalSince(start) < 5)
    }
}

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var total = 0
    func add(_ n: Int) { lock.lock(); total += n; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return total }
}
