// Данные (JSON ↔ plist), архивы (через bsdtar) и общие вспомогательные типы.

import Foundation

enum ConvertError: LocalizedError {
    case noAccess(String)
    case unreadable
    case encodeFailed
    case unsupported
    case noVideoTrack
    case noAudioTrack
    case sourceGone
    case backupFailed(String)
    case replaceFailed(String)
    case toolFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAccess(let path):
            return String(localized: "Нет доступа к \(path). Разрешите доступ в Системных настройках → Конфиденциальность и безопасность → Файлы и папки.")
        case .unreadable: return String(localized: "Не удалось прочитать файл — возможно, он повреждён или в другом формате.")
        case .encodeFailed: return String(localized: "Не удалось записать файл в новом формате.")
        case .unsupported: return String(localized: "Такая конвертация не поддерживается.")
        case .noVideoTrack: return String(localized: "В файле нет видео.")
        case .noAudioTrack: return String(localized: "В файле нет звуковой дорожки.")
        case .sourceGone: return String(localized: "Файл переименовали или удалили во время конвертации.")
        case .backupFailed(let why): return String(localized: "Не удалось положить оригинал в Корзину, файл не изменён: \(why)")
        case .replaceFailed(let why): return String(localized: "Не удалось заменить файл: \(why)")
        case .toolFailed(let why): return why.isEmpty ? String(localized: "Ошибка конвертации.") : why
        }
    }
}

/// Запуск внешней программы. stdout и stderr читаются всё время работы — иначе, когда буфер канала
/// (~64 КБ) заполнится, программа встанет навсегда. Отмена задачи завершает процесс.
enum Subprocess {
    struct Result {
        let status: Int32
        let crashed: Bool
        let stderr: String
    }

    /// `onOutput` получает stdout кусками по мере поступления.
    static func run(_ executable: URL, _ args: [String], onOutput: (@Sendable (Data) -> Void)? = nil) async throws -> Result {
        try Task.checkCancellation()
        let process = Process()
        process.executableURL = executable
        process.arguments = args
        let stdout = Pipe(), stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        let errors = Collector()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Result, Error>) in
                let group = DispatchGroup()
                group.enter()
                process.terminationHandler = { _ in group.leave() }
                do {
                    try process.run()
                } catch {
                    cont.resume(throwing: error)
                    return
                }
                // Отмена могла прийти до запуска — тогда onCancel процесс ещё не застал.
                if Task.isCancelled { stop(process) }
                drain(stdout.fileHandleForReading, group: group) { onOutput?($0) }
                drain(stderr.fileHandleForReading, group: group) { errors.append($0) }
                group.notify(queue: .global()) {
                    cont.resume(returning: Result(status: process.terminationStatus,
                                                  crashed: process.terminationReason == .uncaughtSignal,
                                                  stderr: errors.text))
                }
            }
        } onCancel: {
            stop(process)
        }
    }

    /// SIGTERM, а если через 2 с процесс ещё жив (ffmpeg бывает, что долго дочитывает вход) — SIGKILL.
    private static func stop(_ process: Process) {
        guard process.isRunning else { return }
        process.terminate()
        let pid = process.processIdentifier
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            if process.isRunning { kill(pid, SIGKILL) }
        }
    }

    private static func drain(_ handle: FileHandle, group: DispatchGroup, _ sink: @escaping (Data) -> Void) {
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            while let data = try? handle.read(upToCount: 1 << 16), !data.isEmpty { sink(data) }
            group.leave()
        }
    }

    /// stderr целиком не нужен: храним не больше 1 МБ (начало важнее — там заголовок ffmpeg).
    private final class Collector: @unchecked Sendable {
        private let lock = NSLock()
        private var data = Data()

        func append(_ chunk: Data) {
            lock.lock()
            defer { lock.unlock() }
            if data.count < 1 << 20 { data.append(chunk.prefix((1 << 20) - data.count)) }
        }

        var text: String {
            lock.lock()
            defer { lock.unlock() }
            return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

enum Shell {
    /// Запускает системную утилиту; ошибка — с текстом из stderr.
    static func run(_ tool: String, _ args: [String]) async throws {
        let result = try await Subprocess.run(URL(fileURLWithPath: tool), args)
        try Task.checkCancellation()
        guard result.status == 0, !result.crashed else { throw ConvertError.toolFailed(result.stderr) }
    }
}

enum DataEngine {
    static func convert(_ input: URL, from: String, to output: URL, ext: String) throws {
        let data = try Data(contentsOf: input)
        let object: Any
        do {
            object = from == "json"
                ? try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                : try PropertyListSerialization.propertyList(from: data, format: nil)
        } catch {
            throw ConvertError.unreadable
        }

        let out: Data
        if ext == "json" {
            out = try JSONSerialization.data(withJSONObject: jsonSafe(object),
                                             options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
        } else {
            out = try PropertyListSerialization.data(fromPropertyList: try plistSafe(object), format: .xml, options: 0)
        }
        try out.write(to: output)
    }

    /// Даты и бинарные данные plist в JSON не представимы — превращаем в строки.
    private static func jsonSafe(_ value: Any) -> Any {
        switch value {
        case let d as [String: Any]: return d.mapValues(jsonSafe)
        case let a as [Any]: return a.map(jsonSafe)
        case let date as Date: return ISO8601DateFormatter().string(from: date)
        case let data as Data: return data.base64EncodedString()
        default: return value
        }
    }

    private static func plistSafe(_ value: Any) throws -> Any {
        switch value {
        case let d as [String: Any]: return try d.mapValues(plistSafe)
        case let a as [Any]: return try a.map(plistSafe)
        case is NSNull: throw ConvertError.toolFailed(String(localized: "В JSON есть значения null — в plist их сохранить нельзя."))
        default: return value
        }
    }
}

enum ArchiveEngine {
    private static let bsdtar = "/usr/bin/bsdtar"

    /// Распаковывает архив и упаковывает заново; формат определяется по расширению результата.
    static func convert(_ input: URL, to output: URL, workDir: URL) async throws {
        let extracted = workDir.appendingPathComponent("extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: extracted, withIntermediateDirectories: true)
        try await Shell.run(bsdtar, ["-xf", input.path, "-C", extracted.path])

        let items = try FileManager.default.contentsOfDirectory(atPath: extracted.path)
            .filter { $0 != "__MACOSX" && $0 != ".DS_Store" }
        guard !items.isEmpty else { throw ConvertError.toolFailed(String(localized: "Архив пуст.")) }
        try await Shell.run(bsdtar, ["--no-mac-metadata", "-a", "-cf", output.path, "-C", extracted.path] + items)
    }
}
