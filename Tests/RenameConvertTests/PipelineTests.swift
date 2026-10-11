// Конвейер целиком и слежение за переименованиями через настоящие FSEvents.

import CoreGraphics
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import RenameConvert

@Suite struct PipelineTests {
    init() { _ = TestEnv.ready }

    /// PNG, переименованный в .jpg, — как после переименования в Finder.
    private func renamedPNG(in dir: TempDir) throws -> URL {
        let ctx = CGContext(data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        let png = dir.file("photo.png")
        try ImageEngine.write(ctx.makeImage()!, to: png, type: .png, quality: 1)
        let jpg = dir.file("photo.jpg")
        try FileManager.default.moveItem(at: png, to: jpg)
        return jpg
    }

    private func job(_ url: URL) -> ConversionJob {
        ConversionJob(path: url.path, oldName: "photo.png", plan: Formats.plan(from: "png", to: "jpg")!,
                      params: ConversionParams(), keepOriginal: false)
    }

    @Test func convertsInPlace() async throws {
        let dir = try TempDir()
        let photo = try renamedPNG(in: dir)
        let trashed = try await Pipeline.run(job(photo)) { _ in }
        #expect(trashed == nil)
        #expect(ImageEngine.actualTypeID(of: photo) == UTType.jpeg.identifier)
        // Рабочая папка убрана, рядом ничего лишнего.
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.url.path) == ["photo.jpg"])
    }

    @Test func keepsFinderMetadata() async throws {
        let dir = try TempDir()
        let photo = try renamedPNG(in: dir)
        let fm = FileManager.default
        let created = Date(timeIntervalSince1970: 1_500_000_000)
        try fm.setAttributes([.posixPermissions: 0o600, .creationDate: created], ofItemAtPath: photo.path)
        // Теги Finder хранятся в расширенном атрибуте — массив строк в бинарном plist.
        let tags = try PropertyListSerialization.data(fromPropertyList: ["Red"], format: .binary, options: 0)
        #expect(tags.withUnsafeBytes { setxattr(photo.path, "com.apple.metadata:_kMDItemUserTags", $0.baseAddress, tags.count, 0, 0) } == 0)
        let encoding = Array("windows-1251;1280".utf8)
        #expect(setxattr(photo.path, "com.apple.TextEncoding", encoding, encoding.count, 0, 0) == 0)

        _ = try await Pipeline.run(job(photo)) { _ in }

        let attrs = try fm.attributesOfItem(atPath: photo.path)
        #expect(ImageEngine.actualTypeID(of: photo) == UTType.jpeg.identifier)
        #expect(attrs[.posixPermissions] as? Int == 0o600)
        #expect((attrs[.creationDate] as? Date).map { abs($0.timeIntervalSince(created)) < 1 } == true)
        #expect(try URL(fileURLWithPath: photo.path).resourceValues(forKeys: [.tagNamesKey]).tagNames == ["Red"])
        // Кодировка старого текста к новому файлу не относится.
        #expect(getxattr(photo.path, "com.apple.TextEncoding", nil, 0, 0, 0) < 0)
    }

    @Test func missingSourceFailsWithoutLeftovers() async throws {
        let dir = try TempDir()
        let photo = try renamedPNG(in: dir)
        // Файл исчез до начала (переименовали снова или удалили, пока ждал в очереди) — ошибка, рядом ничего не остаётся.
        try FileManager.default.removeItem(at: photo)
        await #expect(throws: (any Error).self) { try await Pipeline.run(job(photo)) { _ in } }
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.url.path).isEmpty)
    }
}

/// Слежение за переименованиями: FSEvents доставляет события в главную очередь.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct RenameWatcherTests {
    init() { _ = TestEnv.ready }

    private func waitForEvents() async throws { try await Task.sleep(for: .milliseconds(1200)) }

    @Test func pairsRenamesByFileNotJustFolder() async throws {
        let dir = try TempDir(), outside = try TempDir()
        func path(_ name: String) -> String { dir.file(name).path }
        // Не FileManager.createFile: он пишет атомарно, через переименование временного «*.sb-…»,
        // и эти служебные переименования могут попасть в наблюдатель.
        for name in ["a.heic", "b.jpg", "c.png", "d.mov"] { try dir.write(name, Data(name.utf8)) }
        try outside.write("new-b", Data("converted".utf8))

        var seen: [String] = []
        let watcher = RenameWatcher()
        watcher.onRename = { old, new in
            seen.append("\((old as NSString).lastPathComponent) → \((new as NSString).lastPathComponent)")
        }
        watcher.start(paths: [dir.url.path])
        defer { watcher.stop() }
        try await Task.sleep(for: .milliseconds(300))

        rename(path("a.heic"), path("a.jpg"))                       // обычное переименование
        try await waitForEvents()
        rename(outside.file("new-b").path, path("b.jpg"))           // замена файла из другой папки, как делает конвейер
        try await Task.sleep(for: .milliseconds(500))
        rename(path("c.png"), path("c.jpg"))                        // переименование сразу после замены
        try await waitForEvents()
        rename(path("d.mov"), path("d.mp4"))                        // два переименования подряд —
        rename(path("d.mp4"), path("d.mkv"))                        // берётся последнее
        try await waitForEvents()

        #expect(seen == ["a.heic → a.jpg", "c.png → c.jpg", "d.mp4 → d.mkv"])
    }

    @Test func ignoresMovesBetweenFoldersAndHiddenFiles() async throws {
        let dir = try TempDir()
        let fm = FileManager.default
        let sub = dir.file("sub")
        try fm.createDirectory(at: sub, withIntermediateDirectories: true)
        try dir.write("x.png", Data("x".utf8))
        try dir.write(".hidden.png", Data("h".utf8))

        var seen: [String] = []
        let watcher = RenameWatcher()
        watcher.onRename = { old, new in seen.append("\(old) → \(new)") }
        watcher.start(paths: [dir.url.path])
        defer { watcher.stop() }
        try await Task.sleep(for: .milliseconds(300))

        rename(dir.file("x.png").path, sub.appendingPathComponent("x.jpg").path)   // перенос в другую папку
        rename(dir.file(".hidden.png").path, dir.file(".hidden.jpg").path)         // скрытый файл
        try await waitForEvents()

        #expect(seen.isEmpty)
    }
}
