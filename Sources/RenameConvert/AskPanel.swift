// Плавающее окно «Конвертировать?» в правом верхнем углу экрана.

import AppKit
import SwiftUI

@MainActor
final class AskPanelController {
    private weak var model: AppModel?
    private var panel: NSPanel?

    init(model: AppModel) {
        self.model = model
    }

    func show() {
        guard let model else { return }
        let panel = self.panel ?? makePanel(model: model)
        self.panel = panel
        if let screen = NSScreen.main, !panel.isVisible {
            let area = screen.visibleFrame
            panel.setFrameTopLeftPoint(NSPoint(x: area.maxX - panel.frame.width - 16, y: area.maxY - 8))
        }
        panel.orderFrontRegardless()
        NSApp.activate()
        panel.makeKey()
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func makePanel(model: AppModel) -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 300),
                            styleMask: [.titled, .closable, .fullSizeContentView],
                            backing: .buffered, defer: false)
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        let host = NSHostingController(rootView: AskView(model: model))
        host.sizingOptions = [.preferredContentSize]
        panel.contentViewController = host
        return panel
    }
}

struct AskView: View {
    let model: AppModel

    var body: some View {
        if let ask = model.pendingAsks.first {
            AskContent(model: model, ask: ask)
                .id(ask.id)
        }
    }
}

private struct AskContent: View {
    let model: AppModel
    @State var ask: PendingAsk
    @State private var remember = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: ask.job.path))
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Конвертировать в \(ask.job.plan.to.uppercased())?")
                        .font(.headline)
                    Text("\(ask.job.oldName) → \(ask.job.newName)")
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text(((ask.job.directory as NSString).standardizingPath as NSString).abbreviatingWithTildeInPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                Spacer(minLength: 0)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 8)

            Form {
                ParamsSections(params: $ask.job.params, sections: ParamSection.relevant(for: ask.job.plan))
                Section {
                    Toggle("Оригинал в Корзину", isOn: $ask.job.keepOriginal)
                    Toggle("Запомнить для .\(ask.job.plan.from) → .\(ask.job.plan.to)", isOn: $remember)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                if model.pendingAsks.count > 1 {
                    Text("Ещё в очереди: \(model.pendingAsks.count - 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Не конвертировать") { model.resolveAsk(ask, convert: false, remember: remember) }
                    .keyboardShortcut(.cancelAction)
                Button("Конвертировать") { model.resolveAsk(ask, convert: true, remember: remember) }
                    .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .frame(width: 440)
    }
}
