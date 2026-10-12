// Реестр форматов: что во что умеем конвертировать и каким движком.

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum FileCategory: String, Codable, CaseIterable, Identifiable {
    case image, video, audio, document, data, archive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .image: return String(localized: "Картинки")
        case .video: return String(localized: "Видео")
        case .audio: return String(localized: "Аудио")
        case .document: return String(localized: "Документы")
        case .data: return String(localized: "Данные")
        case .archive: return String(localized: "Архивы")
        }
    }

    var symbol: String {
        switch self {
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "waveform"
        case .document: return "doc.text"
        case .data: return "curlybraces"
        case .archive: return "archivebox"
        }
    }
}

enum Engine {
    case image, pdfToImage
    case video, videoToGIF, videoToAudio, videoToImage, gifToVideo
    case audio
    case document
    case data
    case archive
    // Через встроенный ffmpeg
    case ffmpegVideo, ffmpegGIF, ffmpegAudio, ffmpegFrame, ffmpegWebP
}

struct ConversionPlan: Hashable {
    let engine: Engine
    let from: String
    let to: String
}

enum Formats {
    // MARK: Списки расширений

    static let imageWritableTypeIDs = Set((CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? [])

    static let imageTargets = ["jpg", "jpeg", "png", "heic", "heif", "avif", "gif", "tiff", "tif", "bmp",
                               "jp2", "ico", "icns", "psd", "tga", "pdf"].filter { imageTargetType($0) != nil }

    /// Видео, которое читает AVFoundation.
    static let videoSources = ["mov", "mp4", "m4v", "3gp", "3g2"]
    static let videoTargets = ["mov", "mp4", "m4v"]
    /// Видео, которое читает только ffmpeg.
    static let ffmpegVideoSources = ["mkv", "avi", "webm", "flv", "wmv", "mpg", "mpeg", "ts", "mts", "m2ts", "ogv", "vob"]
    static let ffmpegVideoTargets = ["mov", "mp4", "m4v", "mkv"]

    /// Аудио, которое читает afconvert.
    static let audioSources = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "aifc", "caf", "flac", "m4r"]
    static let audioTargets = ["m4a", "wav", "aiff", "aif", "caf", "flac"]
    /// Аудио, которое читает только ffmpeg.
    static let ffmpegAudioSources = ["ogg", "oga", "opus", "wma", "ac3", "amr", "mka", "ape"]

    static var ffmpeg: Bool { FFmpeg.isAvailable }

    static var allVideoSources: [String] { videoSources + (ffmpeg ? ffmpegVideoSources : []) }
    static var allVideoTargets: [String] { ffmpeg ? ffmpegVideoTargets : videoTargets }
    static var allAudioSources: [String] { audioSources + (ffmpeg ? ffmpegAudioSources : []) }
    static var allAudioTargets: [String] { audioTargets + (ffmpeg ? ["mp3"] : []) }
    static var allImageTargets: [String] { imageTargets + (ffmpeg ? ["webp"] : []) }

    static let documentSources = ["txt", "text", "rtf", "html", "htm", "docx", "doc", "odt", "webarchive", "pdf"]
    static let documentTargets = ["txt", "rtf", "html", "htm", "docx", "doc", "odt", "pdf"]

    static let dataFormats = ["json", "plist"]

    static let archiveFormats = ["zip", "tar", "tar.gz", "tgz", "tar.bz2", "tbz", "tbz2", "tar.xz", "txz", "7z"]

    /// Синонимы: переименование между ними ничего не меняет.
    private static let canonical: [String: String] = [
        "jpeg": "jpg", "tif": "tiff", "heif": "heic", "htm": "html", "text": "txt", "aif": "aiff",
        "tgz": "tar.gz", "tbz": "tar.bz2", "tbz2": "tar.bz2", "txz": "tar.xz",
    ]

    static func canonicalExtension(_ ext: String) -> String {
        let e = ext.lowercased()
        return canonical[e] ?? e
    }

    /// Расширение с учётом составных (`archive.tar.gz` → `tar.gz`).
    static func fileExtension(of name: String) -> String {
        let lower = name.lowercased()
        for compound in ["tar.gz", "tar.bz2", "tar.xz"] where lower.hasSuffix("." + compound) {
            return compound
        }
        return (lower as NSString).pathExtension
    }

    // MARK: Типы

    /// Тип ImageIO, в который надо писать картинку с расширением `ext`.
    static func imageTargetType(_ ext: String) -> UTType? {
        let e = ext.lowercased()
        if e == "heif" { return .heic }
        guard let t = UTType(filenameExtension: e), imageWritableTypeIDs.contains(t.identifier) else { return nil }
        return t
    }

    static func isImage(_ ext: String) -> Bool {
        guard !ext.isEmpty, ext != "pdf", let t = UTType(filenameExtension: ext) else { return false }
        return t.conforms(to: .image)
    }

    static func category(of ext: String) -> FileCategory? {
        let e = ext.lowercased()
        if isImage(e) { return .image }
        if videoSources.contains(e) { return .video }
        if audioSources.contains(e) { return .audio }
        if documentSources.contains(e) { return .document }
        if dataFormats.contains(e) { return .data }
        if archiveFormats.contains(e) { return .archive }
        return nil
    }

    // MARK: План

    /// Как конвертировать файл с расширением `from` в `to`; `nil` — не умеем или не нужно.
    static func plan(from: String, to: String) -> ConversionPlan? {
        let f = from.lowercased(), t = to.lowercased()
        guard !f.isEmpty, !t.isEmpty, canonicalExtension(f) != canonicalExtension(t) else { return nil }

        func make(_ engine: Engine) -> ConversionPlan { ConversionPlan(engine: engine, from: f, to: t) }

        if isImage(f) {
            if f == "gif", videoTargets.contains(t) { return make(.gifToVideo) }
            if t == "webp", ffmpeg { return make(.ffmpegWebP) }
            if imageTargetType(t) != nil { return make(.image) }
        }
        let nativeVideo = videoSources.contains(f)
        if nativeVideo || (ffmpeg && ffmpegVideoSources.contains(f)) {
            if nativeVideo, videoTargets.contains(t) { return make(.video) }
            if ffmpeg, ffmpegVideoTargets.contains(t) { return make(.ffmpegVideo) }
            // GIF с подбором палитры через ffmpeg заметно лучше.
            if t == "gif" { return make(ffmpeg ? .ffmpegGIF : .videoToGIF) }
            if nativeVideo, audioTargets.contains(t) { return make(.videoToAudio) }
            if ffmpeg, allAudioTargets.contains(t) { return make(.ffmpegAudio) }
            if t != "pdf", imageTargetType(t) != nil { return make(nativeVideo ? .videoToImage : .ffmpegFrame) }
        }
        if audioSources.contains(f), audioTargets.contains(t) { return make(.audio) }
        if ffmpeg, allAudioSources.contains(f), allAudioTargets.contains(t) { return make(.ffmpegAudio) }
        if f == "pdf", t != "pdf", imageTargetType(t) != nil { return make(.pdfToImage) }
        if documentSources.contains(f), documentTargets.contains(t) { return make(.document) }
        if dataFormats.contains(f), dataFormats.contains(t) { return make(.data) }
        if archiveFormats.contains(f), archiveFormats.contains(t) { return make(.archive) }
        return nil
    }

    /// Во что можно сконвертировать файл с расширением `ext` — для контекстного меню Finder.
    /// Группы по категориям (своя категория первой), без синонимов (jpg, но не jpeg).
    static func targets(from ext: String) -> [[String]] {
        let groups: [(FileCategory, [String])] = [
            (.image, allImageTargets), (.video, allVideoTargets), (.audio, allAudioTargets),
            (.document, documentTargets), (.data, dataFormats), (.archive, archiveFormats),
        ]
        let own = category(of: ext) ?? (allVideoSources.contains(ext.lowercased()) ? .video
                                         : allAudioSources.contains(ext.lowercased()) ? .audio : nil)
        var seen = Set<String>()
        let ordered = groups.filter { $0.0 == own } + groups.filter { $0.0 != own }
        return ordered.compactMap { _, candidates in
            let found = candidates.filter { plan(from: ext, to: $0) != nil && seen.insert(canonicalExtension($0)).inserted }
            return found.isEmpty ? nil : found
        }
    }

    /// Все расширения, которые встречаются в планах, — для выбора в правилах.
    static func knownExtensions(in category: FileCategory) -> [String] {
        let all: [String]
        switch category {
        case .image: all = allImageTargets + ["webp", "raw", "dng", "cr2", "nef", "arw"]
        case .video: all = allVideoSources + allVideoTargets
        case .audio: all = allAudioSources + allAudioTargets
        case .document: all = documentSources
        case .data: all = dataFormats
        case .archive: all = archiveFormats
        }
        var seen = Set<String>()
        return all.filter { seen.insert(canonicalExtension($0)).inserted }
    }
}
