// Чистая логика: форматы, правила, версии, JSON ↔ plist.

import Foundation
import Testing
@testable import RenameConvert

@Suite struct FormatsTests {
    init() { _ = TestEnv.ready }

    @Test func extensions() {
        #expect(Formats.fileExtension(of: "Archive.TAR.GZ") == "tar.gz")
        #expect(Formats.fileExtension(of: "photo.HEIC") == "heic")
        #expect(Formats.fileExtension(of: "README") == "")
        #expect(Formats.canonicalExtension("JPEG") == "jpg")
        #expect(Formats.canonicalExtension("tgz") == "tar.gz")
    }

    @Test func synonymsAndUnknownGiveNoPlan() {
        #expect(Formats.plan(from: "jpg", to: "jpeg") == nil)
        #expect(Formats.plan(from: "HEIC", to: "heic") == nil)
        #expect(Formats.plan(from: "crdownload", to: "mp4") == nil)
        #expect(Formats.plan(from: "", to: "jpg") == nil)
        #expect(Formats.plan(from: "zip", to: "jpg") == nil)
    }

    @Test(arguments: [
        ("heic", "jpg", Engine.image), ("png", "pdf", .image), ("pdf", "png", .pdfToImage),
        ("gif", "mp4", .gifToVideo), ("mov", "mp4", .video), ("mov", "m4a", .videoToAudio),
        ("mov", "jpg", .videoToImage), ("wav", "flac", .audio), ("docx", "pdf", .document),
        ("txt", "rtf", .document), ("json", "plist", .data), ("zip", "tar.gz", .archive),
    ])
    func nativePlans(from: String, to: String, engine: Engine) {
        #expect(Formats.plan(from: from, to: to)?.engine == engine)
    }

    @Test(.enabled(if: TestEnv.hasFFmpeg), arguments: [
        ("mkv", "mp4", Engine.ffmpegVideo), ("mov", "gif", .ffmpegGIF), ("wav", "mp3", .ffmpegAudio),
        ("ogg", "m4a", .ffmpegAudio), ("mkv", "png", .ffmpegFrame), ("heic", "webp", .ffmpegWebP),
    ])
    func ffmpegPlans(from: String, to: String, engine: Engine) {
        #expect(Formats.plan(from: from, to: to)?.engine == engine)
    }
}

@Suite struct FinderMenuTests {
    init() { _ = TestEnv.ready }

    @Test func targetsStartWithOwnCategoryWithoutSynonyms() {
        let image = Formats.targets(from: "png")
        #expect(image.first?.contains("jpg") == true)
        #expect(!image.joined().contains("png") && !image.joined().contains("jpeg") && !image.joined().contains("tif"))
        #expect(Formats.targets(from: "mov").first?.contains("mp4") == true)
        #expect(Formats.targets(from: "docx").first?.contains("pdf") == true)
        #expect(Formats.targets(from: "crdownload").isEmpty)
        // Каждый предложенный формат действительно конвертируется.
        for ext in ["heic", "mov", "wav", "pdf", "json", "zip", "gif"] {
            for to in Formats.targets(from: ext).joined() { #expect(Formats.plan(from: ext, to: to) != nil) }
        }
    }

    @Test func parsesLinkFromExtension() throws {
        let url = try #require(URL(string: "renameconvert://convert?to=JPG&path=/a/b%20c%26d.png&path=/x/y.heic&path=relative.png"))
        let parsed = try #require(FinderMenu.parse(url))
        #expect(parsed.to == "jpg")
        #expect(parsed.paths == ["/a/b c&d.png", "/x/y.heic"])
        #expect(FinderMenu.parse(URL(string: "renameconvert://convert?to=jpg")!) == nil)
        #expect(FinderMenu.parse(URL(string: "other://convert?to=jpg&path=/a.png")!) == nil)
    }

    @Test func destinationDoesNotOverwrite() throws {
        let dir = try TempDir()
        let source = try dir.write("photo.png", Data([1]))
        #expect(FinderMenu.destination(for: source.path, to: "jpg") == dir.file("photo.jpg").path)
        try dir.write("photo.jpg", Data([2]))
        try dir.write("photo 2.jpg", Data([3]))
        #expect(FinderMenu.destination(for: source.path, to: "jpg") == dir.file("photo 3.jpg").path)
        #expect(FinderMenu.destination(for: dir.file("a.tar.gz").path, to: "zip") == dir.file("a.zip").path)
        #expect(FinderMenu.destination(for: dir.file("README").path, to: "txt") == nil)
    }
}

@Suite struct RulesTests {
    init() { _ = TestEnv.ready }

    @Test func mostSpecificRuleWins() {
        let rules = [
            Rule(from: .any, to: .any, action: .convert),
            Rule(from: .category(.video), to: .any, action: .ask),
            Rule(from: .ext("mov"), to: .ext("mp4"), action: .skip),
        ]
        #expect(rules.bestMatch(from: "mov", to: "mp4")?.action == .skip)
        #expect(rules.bestMatch(from: "mov", to: "m4v")?.action == .ask)
        #expect(rules.bestMatch(from: "png", to: "jpg")?.action == .convert)
    }

    @Test func tieGoesToRuleHigherInList() {
        let rules = [Rule(from: .ext("png"), to: .any, action: .skip), Rule(from: .any, to: .ext("jpg"), action: .convert)]
        #expect(rules.bestMatch(from: "png", to: "jpg")?.action == .skip)
    }

    @Test func extensionSelectorUsesSynonyms() {
        #expect(RuleSelector.ext("jpeg").matches("JPG"))
        #expect(!RuleSelector.ext("png").matches("jpg"))
    }

    @Test func selectorRoundTrip() throws {
        let rules = [Rule(from: .category(.image), to: .ext("webp"), action: .ask, keepOriginal: .discard)]
        let decoded = try JSONDecoder().decode([Rule].self, from: JSONEncoder().encode(rules))
        #expect(decoded == rules)
    }
}

@MainActor
@Suite struct UpdaterVersionTests {
    @Test(arguments: [("2.4", "2.3", true), ("2.10", "2.9", true), ("2.3", "2.3", false), ("2.3.1", "2.3", true),
                      ("2.3", "2.3.0", false), ("1.9", "2.0", false)])
    func isNewer(a: String, b: String, newer: Bool) {
        #expect(Updater.isNewer(a, than: b) == newer)
    }
}

@Suite struct DataEngineTests {
    init() { _ = TestEnv.ready }

    @Test func jsonToPlistAndBack() throws {
        let dir = try TempDir()
        let json = try dir.write("in.json", Data(#"{"name":"Файл","n":3,"ok":true,"list":[1,2.5]}"#.utf8))
        let plist = dir.file("out.plist")
        try DataEngine.convert(json, from: "json", to: plist, ext: "plist")
        let object = try PropertyListSerialization.propertyList(from: Data(contentsOf: plist), format: nil) as? [String: Any]
        #expect(object?["name"] as? String == "Файл")
        #expect(object?["ok"] as? Bool == true)

        let back = dir.file("back.json")
        try DataEngine.convert(plist, from: "plist", to: back, ext: "json")
        let again = try JSONSerialization.jsonObject(with: Data(contentsOf: back)) as? [String: Any]
        #expect(again?["n"] as? Int == 3)
    }

    @Test func nullCannotGoToPlist() throws {
        let dir = try TempDir()
        let json = try dir.write("in.json", Data(#"{"a":null}"#.utf8))
        #expect(throws: ConvertError.self) { try DataEngine.convert(json, from: "json", to: dir.file("o.plist"), ext: "plist") }
    }

    @Test func brokenJsonIsUnreadable() throws {
        let dir = try TempDir()
        let json = try dir.write("in.json", Data("{oops".utf8))
        #expect(throws: ConvertError.self) { try DataEngine.convert(json, from: "json", to: dir.file("o.plist"), ext: "plist") }
    }
}
