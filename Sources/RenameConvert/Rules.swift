// Правила («спросить / сразу / не конвертировать») и параметры конвертации.

import Foundation

enum RuleAction: String, Codable, CaseIterable, Identifiable {
    case ask, convert, skip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ask: return String(localized: "Спросить")
        case .convert: return String(localized: "Конвертировать сразу")
        case .skip: return String(localized: "Не конвертировать")
        }
    }
}

enum KeepOriginal: String, Codable, CaseIterable, Identifiable {
    case inherit, keep, discard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inherit: return String(localized: "Как в настройках")
        case .keep: return String(localized: "В Корзину")
        case .discard: return String(localized: "Не сохранять")
        }
    }
}

/// «Из чего» или «во что» в правиле: любой файл, категория или конкретное расширение.
enum RuleSelector: Hashable, Codable {
    case any
    case category(FileCategory)
    case ext(String)

    var title: String {
        switch self {
        case .any: return String(localized: "Любой")
        case .category(let c): return c.title
        case .ext(let e): return "." + e
        }
    }

    var specificity: Int {
        switch self {
        case .any: return 0
        case .category: return 1
        case .ext: return 2
        }
    }

    func matches(_ ext: String) -> Bool {
        switch self {
        case .any: return true
        case .category(let c): return Formats.category(of: ext) == c
        case .ext(let e): return Formats.canonicalExtension(e) == Formats.canonicalExtension(ext)
        }
    }

    // Храним строкой: "*", "cat:video", "ext:png".
    init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        if s.hasPrefix("cat:"), let c = FileCategory(rawValue: String(s.dropFirst(4))) {
            self = .category(c)
        } else if s.hasPrefix("ext:") {
            self = .ext(String(s.dropFirst(4)))
        } else {
            self = .any
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .any: try c.encode("*")
        case .category(let cat): try c.encode("cat:" + cat.rawValue)
        case .ext(let e): try c.encode("ext:" + e)
        }
    }
}

struct Rule: Codable, Identifiable, Hashable {
    var id = UUID()
    var from: RuleSelector
    var to: RuleSelector
    var action: RuleAction
    var keepOriginal: KeepOriginal = .inherit

    static let defaults = [Rule(from: .category(.video), to: .any, action: .ask)]
}

extension Array where Element == Rule {
    /// Самое конкретное подходящее правило (расширение важнее категории, категория важнее «любой»).
    func bestMatch(from: String, to: String) -> Rule? {
        filter { $0.from.matches(from) && $0.to.matches(to) }
            .enumerated()
            .max { a, b in
                let sa = a.element.from.specificity + a.element.to.specificity
                let sb = b.element.from.specificity + b.element.to.specificity
                return sa != sb ? sa < sb : a.offset > b.offset   // при равенстве — то, что выше в списке
            }?.element
    }
}

// MARK: - Параметры

enum VideoCodec: String, Codable, CaseIterable, Identifiable {
    case auto, h264, hevc
    var id: String { rawValue }
    var title: String {
        switch self {
        case .auto: return String(localized: "Авто (без перекодирования, если можно)")
        case .h264: return String(localized: "H.264 — максимальная совместимость")
        case .hevc: return String(localized: "HEVC (H.265) — меньше размер")
        }
    }
}

enum VideoResolution: Int, Codable, CaseIterable, Identifiable {
    case original = 0, p2160 = 2160, p1080 = 1080, p720 = 720, p480 = 480
    var id: Int { rawValue }
    var title: String { self == .original ? String(localized: "Исходное") : (self == .p2160 ? "4K (2160p)" : "\(rawValue)p") }
}

enum PageSize: String, Codable, CaseIterable, Identifiable {
    case a4, letter
    var id: String { rawValue }
    var title: String { self == .a4 ? "A4" : "US Letter" }
    var points: CGSize { self == .a4 ? CGSize(width: 595, height: 842) : CGSize(width: 612, height: 792) }
}

struct ConversionParams: Codable, Equatable, Sendable {
    var imageQuality = 0.9
    var videoCodec = VideoCodec.auto
    var videoResolution = VideoResolution.original
    var videoFPS = 0                    // 0 — исходная
    var stripMetadata = false
    var gifFPS = 12
    var gifMaxWidth = 480               // 0 — исходная ширина
    var audioBitrate = 256              // кбит/с, для AAC
    var pdfPageSize = PageSize.a4

    static let fpsOptions = [0, 24, 25, 30, 50, 60]
    static let gifFPSOptions = [8, 10, 12, 15, 20, 25]
    static let gifWidthOptions = [320, 480, 640, 800, 0]
    static let bitrateOptions = [128, 160, 192, 256, 320]
}

/// Какие группы параметров имеют смысл для конкретной конвертации.
enum ParamSection: CaseIterable {
    case image, video, gif, audio, document

    static func relevant(for plan: ConversionPlan) -> [ParamSection] {
        switch plan.engine {
        case .image, .pdfToImage, .videoToImage, .ffmpegFrame, .ffmpegWebP: return [.image]
        case .video, .gifToVideo, .ffmpegVideo: return [.video]
        case .videoToGIF, .ffmpegGIF: return [.gif]
        case .videoToAudio, .audio, .ffmpegAudio: return ["m4a", "mp3"].contains(plan.to) ? [.audio] : []
        case .document: return plan.to == "pdf" ? [.document] : []
        case .data, .archive: return []
        }
    }
}
