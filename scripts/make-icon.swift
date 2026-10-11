// Рисует иконку приложения и собирает Resources/AppIcon.icns.
// Запуск: swift scripts/make-icon.swift Resources/AppIcon.icns

import AppKit

func symbol(_ name: String, pointSize: CGFloat, color: NSColor) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        .applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(config)!
}

func drawCentered(_ image: NSImage, at center: CGPoint) {
    let s = image.size
    image.draw(in: CGRect(x: center.x - s.width / 2, y: center.y - s.height / 2, width: s.width, height: s.height))
}

func renderIcon(size px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 1024, height: 1024)   // рисуем в координатах 1024×1024
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Плашка по сетке иконок macOS: 824×824 с отступом 100.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let path = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor.white.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    let top = NSColor(srgbRed: 0.33, green: 0.67, blue: 1.00, alpha: 1)
    let bottom = NSColor(srgbRed: 0.45, green: 0.28, blue: 0.96, alpha: 1)
    NSGradient(starting: bottom, ending: top)!.draw(in: path, angle: 90)

    // Лёгкий блик сверху.
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSGradient(starting: NSColor.white.withAlphaComponent(0.22), ending: NSColor.white.withAlphaComponent(0))!
        .draw(in: CGRect(x: 100, y: 512, width: 824, height: 412), angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Картинка.
    drawCentered(symbol("photo", pointSize: 360, color: .white), at: CGPoint(x: 490, y: 540))

    // Значок конвертации.
    let badgeCenter = CGPoint(x: 700, y: 330)
    let badge = NSBezierPath(ovalIn: CGRect(x: badgeCenter.x - 150, y: badgeCenter.y - 150, width: 300, height: 300))
    NSGraphicsContext.saveGraphicsState()
    let badgeShadow = NSShadow()
    badgeShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    badgeShadow.shadowBlurRadius = 20
    badgeShadow.shadowOffset = NSSize(width: 0, height: -8)
    badgeShadow.set()
    NSColor.white.setFill()
    badge.fill()
    NSGraphicsContext.restoreGraphicsState()
    drawCentered(symbol("arrow.triangle.2.circlepath", pointSize: 150, color: bottom), at: badgeCenter)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns")
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let data = renderIcon(size: base * scale).representation(using: .png, properties: [:])!
        try data.write(to: iconset.appendingPathComponent(name))
    }
}
// Превью для README.
try renderIcon(size: 512).representation(using: .png, properties: [:])!
    .write(to: output.deletingPathExtension().appendingPathExtension("png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(task.terminationStatus == 0 ? "Иконка: \(output.path)" : "iconutil завершился с ошибкой")
