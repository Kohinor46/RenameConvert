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
        case .replaceFailed(let why): return String(localized: "Не удалось заменить файл: \(why)")
        case .toolFailed(let why): return why.isEmpty ? String(localized: "Ошибка конвертации.") : why
        }
    }
}

enum Shell {
    /// Запускает системную утилиту; ошибка — с текстом из stderr.
    static func run(_ tool: String, _ args: [String]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: tool)
            process.arguments = args
            let stderr = Pipe()
            process.standardError = stderr
            process.standardOutput = FileHandle.nullDevice
            process.terminationHandler = { p in
                let message = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if p.terminationStatus == 0 {
                    cont.resume()
                } else {
                    cont.resume(throwing: ConvertError.toolFailed(message))
                }
            }
            do { try process.run() } catch { cont.resume(throwing: error) }
        }
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
