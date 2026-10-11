// Слежение за переименованиями через FSEvents.

import Foundation

/// Ловит пары событий переименования FSEvents (старый путь → новый путь).
/// Пара — два события об одном и том же файле (inode) в одной папке.
final class RenameWatcher {
    private struct Event {
        let path: String
        let fileID: UInt64?
        let time: Date
        var directory: String { (path as NSString).deletingLastPathComponent }
    }

    private var stream: FSEventStreamRef?
    /// События без пары (ждут вторую половину не дольше 3 с).
    private var pending: [Event] = []
    private var roots: [String] = []
    private let libraryPrefix = NSHomeDirectory() + "/Library/"
    private let cloudPrefixes = [NSHomeDirectory() + "/Library/Mobile Documents/",
                                 NSHomeDirectory() + "/Library/CloudStorage/"]
    var onRename: ((_ old: String, _ new: String) -> Void)?

    deinit { stop() }

    func start(paths: [String]) {
        stop()
        roots = paths.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        guard !paths.isEmpty else { return }

        var ctx = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                       retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, count, pathsPtr, flagsPtr, _ in
            guard let info else { return }
            let me = Unmanaged<RenameWatcher>.fromOpaque(info).takeUnretainedValue()
            // С UseExtendedData вместо путей приходят словари: путь и inode файла.
            let items = (unsafeBitCast(pathsPtr, to: NSArray.self) as? [NSDictionary]) ?? []
            let entries = items.map { item in
                (path: item[kFSEventStreamEventExtendedDataPathKey] as? String ?? "",
                 fileID: (item[kFSEventStreamEventExtendedFileIDKey] as? NSNumber)?.uint64Value)
            }
            let flags = Array(UnsafeBufferPointer(start: flagsPtr, count: count))
            me.handle(entries: entries, flags: flags)
        }
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
                                             | kFSEventStreamCreateFlagUseExtendedData)
        guard let s = FSEventStreamCreate(nil, callback, &ctx, paths as CFArray,
                                          FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.2, flags) else {
            Log.error("Не удалось создать FSEventStream для \(paths)")
            return
        }
        stream = s
        FSEventStreamSetDispatchQueue(s, .main)
        FSEventStreamStart(s)
    }

    func stop() {
        guard let s = stream else { return }
        FSEventStreamStop(s)
        FSEventStreamInvalidate(s)
        FSEventStreamRelease(s)
        stream = nil
    }

    private func shouldIgnore(_ path: String) -> Bool {
        // ~/Library пропускаем (там постоянная служебная активность), кроме облачных
        // дисков и случаев, когда пользователь сам добавил папку внутри Library.
        if path.hasPrefix(libraryPrefix),
           !cloudPrefixes.contains(where: path.hasPrefix),
           !roots.contains(where: { $0.hasPrefix(libraryPrefix) && path.hasPrefix($0) }) { return true }
        // Скрытые файлы и папки (.Trash, .git, наши временные файлы и т.п.)
        return path.split(separator: "/").contains { $0.hasPrefix(".") }
    }

    private func handle(entries: [(path: String, fileID: UInt64?)], flags: [FSEventStreamEventFlags]) {
        let now = Date()
        pending.removeAll { now.timeIntervalSince($0.time) > 3 }

        let renamed = FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)
        let isFile = FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)

        for (entry, f) in zip(entries, flags) where f & renamed != 0 && f & isFile != 0
            && !entry.path.isEmpty && !shouldIgnore(entry.path) {
            let event = Event(path: entry.path, fileID: entry.fileID, time: now)
            guard let i = pending.lastIndex(where: { isPair($0, event) }) else {
                pending.append(event)
                continue
            }
            let other = pending.remove(at: i)
            let fm = FileManager.default
            switch (fm.fileExists(atPath: other.path), fm.fileExists(atPath: event.path)) {
            case (false, true): onRename?(other.path, event.path)
            case (true, false): onRename?(event.path, other.path)
            case (true, true): break                 // сменился только регистр букв — формат тот же
            case (false, false): pending.append(event)   // файл уже переименовали снова — ждём следующее событие
            }
        }
    }

    /// Две половины одного переименования: разные имена в одной папке, один и тот же файл.
    /// Без inode (некоторые сетевые диски) — как раньше, только по папке.
    private func isPair(_ a: Event, _ b: Event) -> Bool {
        guard a.path != b.path, a.directory == b.directory else { return false }
        if let x = a.fileID, let y = b.fileID { return x == y }
        return true
    }
}
