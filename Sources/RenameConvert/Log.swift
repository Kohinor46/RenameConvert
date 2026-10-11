// Журнал работы в ~/Library/Logs/RenameConvert/RenameConvert.log (прикладывается к отчёту об ошибке).

import Foundation

enum Log {
    /// Путь можно переопределить через RC_LOG — для тестов, чтобы не засорять настоящий журнал.
    static let url: URL = ProcessInfo.processInfo.environment["RC_LOG"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/RenameConvert/RenameConvert.log")

    private static let queue = DispatchQueue(label: "RenameConvert.log")
    private static let maxSize = 2 * 1024 * 1024
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func info(_ message: String) { write("INFO", message) }
    static func error(_ message: String) { write("ERROR", message) }

    private static func write(_ level: String, _ message: String) {
        let line = "\(formatter.string(from: Date())) [\(level)] \(message)\n"
        queue.async {
            let fm = FileManager.default
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            // Простая ротация: при превышении размера текущий файл становится .1
            if let size = (try? fm.attributesOfItem(atPath: url.path))?[.size] as? Int, size > maxSize {
                let old = url.appendingPathExtension("1")
                try? fm.removeItem(at: old)
                try? fm.moveItem(at: url, to: old)
            }
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                try? handle.close()
            } else {
                try? Data(line.utf8).write(to: url)
            }
        }
    }

    /// Последние строки журнала (для отчёта).
    static func tail(lines: Int = 400) -> String {
        queue.sync {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
            return text.split(separator: "\n", omittingEmptySubsequences: false).suffix(lines).joined(separator: "\n")
        }
    }
}
