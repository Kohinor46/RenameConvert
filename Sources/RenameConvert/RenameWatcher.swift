// Слежение за переименованиями через FSEvents.

import Foundation

/// Ловит пары событий переименования FSEvents (старый путь → новый путь).
final class RenameWatcher {
    private var stream: FSEventStreamRef?
    private var pendingOld: [(path: String, time: Date)] = []
    private var pendingNew: [(path: String, time: Date)] = []
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
            let paths = (unsafeBitCast(pathsPtr, to: NSArray.self) as? [String]) ?? []
            let flags = Array(UnsafeBufferPointer(start: flagsPtr, count: count))
            me.handle(paths: paths, flags: flags)
        }
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
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

    private func handle(paths: [String], flags: [FSEventStreamEventFlags]) {
        let now = Date()
        pendingOld.removeAll { now.timeIntervalSince($0.time) > 3 }
        pendingNew.removeAll { now.timeIntervalSince($0.time) > 3 }

        let renamed = FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)
        let isFile = FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)

        for (path, f) in zip(paths, flags) where f & renamed != 0 && f & isFile != 0 && !shouldIgnore(path) {
            let dir = (path as NSString).deletingLastPathComponent
            let sameDir: ((path: String, time: Date)) -> Bool = { ($0.path as NSString).deletingLastPathComponent == dir }

            if FileManager.default.fileExists(atPath: path) {
                if let i = pendingOld.lastIndex(where: sameDir) {
                    onRename?(pendingOld.remove(at: i).path, path)
                } else {
                    pendingNew.append((path, now))
                }
            } else {
                if let i = pendingNew.lastIndex(where: sameDir) {
                    onRename?(path, pendingNew.remove(at: i).path)
                } else {
                    pendingOld.append((path, now))
                }
            }
        }
    }
}
