// Поддержка проекта: перевод картой через CloudTips и USDT в сети TON.
// Ссылка и адрес берутся из Info.plist (RCDonateCloudTips, RCDonateUSDTTON).

import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI

enum Donation {
    static let cloudTips: URL? = (Bundle.main.object(forInfoDictionaryKey: "RCDonateCloudTips") as? String).flatMap(URL.init(string:))
    static let usdtTON: String? = Bundle.main.object(forInfoDictionaryKey: "RCDonateUSDTTON") as? String

    static var isConfigured: Bool { cloudTips != nil || usdtTON != nil }

    /// После скольких успешных конвертаций один раз напомнить о поддержке.
    static let promptAfterConversions = 50

    /// QR-код с чёткими (не размытыми) модулями.
    static func qrCode(for text: String, size: CGFloat) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}

struct DonateTab: View {
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.pink)
                    Text("RenameConvert бесплатный. Если он экономит вам время — поддержите разработку.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            if let url = Donation.cloudTips {
                Section("Банковской картой") {
                    LabeledContent {
                        Link(destination: url) {
                            Label("Перевести через CloudTips", systemImage: "creditcard")
                        }
                        .buttonStyle(.borderedProminent)
                    } label: {
                        Text("Карты российских банков")
                    }
                }
            }

            if let address = Donation.usdtTON {
                Section("Криптовалютой") {
                    HStack(alignment: .top, spacing: 18) {
                        if let qr = Donation.qrCode(for: address, size: 150) {
                            Image(nsImage: qr)
                                .interpolation(.none)
                                .frame(width: 150, height: 150)
                                .padding(8)
                                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("USDT · сеть TON")
                                .font(.title3.bold())
                            Text(verbatim: address)
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(copied ? "Скопировано" : "Скопировать адрес",
                                   systemImage: copied ? "checkmark" : "doc.on.doc") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(address, forType: .string)
                                copied = true
                            }
                            Label("Отправляйте только USDT в сети TON — иначе средства могут потеряться.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.callout)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .formStyle(.grouped)
    }
}
