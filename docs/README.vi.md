<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · **Tiếng Việt** · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Ứng dụng trên thanh menu macOS: đổi phần mở rộng của tệp trong Finder và định dạng của tệp cũng thay đổi theo.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Biểu tượng](../Resources/AppIcon.png)

## Cài đặt

Tải **RenameConvert.dmg** từ [bản phát hành mới nhất](https://github.com/Kohinor46/RenameConvert/releases/latest)
rồi kéo ứng dụng vào thư mục Ứng dụng. Yêu cầu macOS 15 trở lên, Apple Silicon hoặc Intel.

Ứng dụng chưa được công chứng (notarize), vì vậy macOS sẽ chặn lần khởi chạy đầu tiên: bấm chuột phải vào ứng dụng → **Mở**
(hoặc **Vẫn mở** trong Cài đặt hệ thống → Quyền riêng tư & Bảo mật).

## Ủng hộ dự án

RenameConvert miễn phí. Nếu ứng dụng giúp bạn tiết kiệm thời gian, bạn có thể ủng hộ việc phát triển:

- **Thẻ ngân hàng (ngân hàng Nga):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, chỉ mạng TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Chỉ gửi USDT trên mạng TON — coin hoặc mạng khác có thể bị mất.

Các tùy chọn tương tự, kèm mã QR, có trong ứng dụng: menu → "Ủng hộ dự án ♥…".

## Tính năng

| Danh mục | Từ | Sang |
|---|---|---|
| Hình ảnh | jpg, png, heic, webp, gif, tiff, bmp, RAW và nhiều định dạng khác | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · âm thanh (m4a, **mp3**, wav, aiff, caf, flac) · khung hình (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (động) |
| Âm thanh | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Tài liệu | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → hình ảnh (trang đầu tiên) |
| Dữ liệu | json, plist | json, plist |
| Kho lưu trữ | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | tương tự |

Các định dạng mà macOS không tự xử lý được (WebP, MP3, MKV, AVI, WebM, OGG…) được chuyển đổi bằng
**FFmpeg 7.1** tích hợp sẵn (LGPL 2.1, kèm LAME và libwebp). FFmpeg được biên dịch từ mã nguồn chính thức bằng `scripts/build-ffmpeg.sh`,
có kiểm tra SHA-256, và chỉ phụ thuộc vào các thư viện hệ thống.

**Menu ngữ cảnh Finder:** bấm chuột phải vào một tệp (hoặc nhiều tệp) → **Chuyển đổi sang** → chọn định dạng.
Tệp được chuyển đổi ngay, như thể bạn đã đổi phần mở rộng. Tiện ích mở rộng Finder được bật ở lần chạy đầu tiên;
bạn có thể tắt nó trong Cài đặt hệ thống → Cài đặt chung → Mục đăng nhập & tiện ích mở rộng (hoặc trong ứng dụng: Cài đặt → “Cài đặt tiện ích mở rộng Finder…”).

**Quy tắc.** Với mọi cặp "từ → sang" (một phần mở rộng, một danh mục hoặc "bất kỳ"), bạn chọn cách xử lý:
hỏi trước, chuyển đổi ngay, hoặc không chuyển đổi — và có giữ lại bản gốc hay không.
Quy tắc cụ thể nhất sẽ được ưu tiên; mặc định video là "Hỏi" và mọi thứ khác là "Chuyển đổi ngay".

**Bảng xác nhận** xuất hiện ở góc trên bên phải: thay đổi tham số cho riêng lần chuyển đổi này
và ghi nhớ lựa chọn cho cặp phần mở rộng này.

**Tham số:** chất lượng JPEG/HEIC/AVIF/WebP; với video — codec (không mã hóa lại / H.264 / HEVC),
độ phân giải (4K…480p, không bao giờ upscale), tốc độ khung hình, xóa vị trí và siêu dữ liệu cá nhân;
tốc độ khung hình và chiều rộng GIF; bitrate AAC/MP3; kích thước trang PDF.

**Cập nhật:** nút "Kiểm tra bản cập nhật" và tự động kiểm tra hằng ngày trên
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Bản cập nhật được tải về,
xác minh bằng SHA-256 và chữ ký mã, rồi được cài đặt kèm khởi chạy lại ứng dụng.

**Báo cáo lỗi:** menu → "Báo cáo lỗi…" (hoặc nút trong thông báo lỗi) sẽ tạo một email gửi
nhà phát triển, gồm mô tả của bạn, thông tin hệ thống và đính kèm nhật ký ứng dụng. Nhật ký:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 ngôn ngữ:** tiếng Anh, tiếng Nga, tiếng Đức, tiếng Pháp, tiếng Tây Ban Nha, tiếng Ý, tiếng Bồ Đào Nha (Brazil), tiếng Hà Lan, tiếng Ba Lan,
tiếng Ukraina, tiếng Séc, tiếng Thụy Điển, tiếng Thổ Nhĩ Kỳ, tiếng Ả Rập, tiếng Do Thái, tiếng Hindi, tiếng Indonesia, tiếng Việt, tiếng Thái, tiếng Nhật, tiếng Hàn,
tiếng Trung (Giản thể và Phồn thể).

**Ngoài ra:** thư mục theo dõi và danh sách loại trừ, tiến trình và nút hủy trên thanh menu, lịch sử với "Khôi phục bản gốc",
bản gốc được chuyển vào Thùng rác, thông báo, khởi chạy khi đăng nhập. Mọi thứ đều chạy cục bộ — tệp không bao giờ rời khỏi máy Mac của bạn.

## Biên dịch

Yêu cầu macOS 15+ và Command Line Tools (`xcode-select --install`). Xcode là tùy chọn,
nhưng có thể mở dự án trong Xcode dưới dạng gói Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universal: Apple Silicon + Intel); biên dịch FFmpeg ở lần chạy đầu (~15 phút)
./build.sh install    # cài đặt vào ~/Applications và khởi chạy
./build.sh dist       # build/RenameConvert.zip (cho tự động cập nhật) và build/RenameConvert.dmg
./build.sh release    # dist + phát hành bản v<version> trên GitHub
```

Bản dịch: `scripts/extract-strings.py` thu thập các chuỗi giao diện vào `Resources/Localization/keys.json`;
`--check` kiểm tra rằng mọi ngôn ngữ đều có đủ mọi chuỗi với các placeholder khớp nhau.
Video quảng bá: `scripts/promo/make-promo.sh` (lồng tiếng bằng `say`, khung hình SwiftUI, ghép bằng FFmpeg).

## Kiến trúc

| Tệp | Mục đích |
|---|---|
| `RenameWatcher.swift` | FSEvents: bắt các cặp "tên cũ → tên mới" |
| `Formats.swift` | Danh mục định dạng: engine nào xử lý một cặp phần mở rộng |
| `Rules.swift` | Quy tắc và tham số chuyển đổi |
| `Pipeline.swift` | Thư mục làm việc, chạy engine, chuyển bản gốc vào Thùng rác, thay thế nguyên tử |
| `Engines/ImageEngine.swift` | Hình ảnh (ImageIO), PDF → hình ảnh |
| `Engines/MediaEngine.swift` | Video, GIF, âm thanh (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Tài liệu (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, kho lưu trữ (bsdtar), lỗi dùng chung |
| `Engines/FFmpegEngine.swift` | FFmpeg tích hợp: WebP, MP3, MKV, AVI, WebM, OGG, GIF dùng bảng màu |
| `Updater.swift` | Kiểm tra và cài đặt bản cập nhật từ GitHub Releases |
| `BugReport.swift`, `Log.swift` | Báo cáo lỗi qua email, nhật ký ứng dụng |
| `AppModel.swift` | Cài đặt, hàng đợi, lời nhắc, lịch sử, thông báo |
| `AskPanel.swift`, `ParamsForm.swift` | Bảng xác nhận và biểu mẫu tham số |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu trên thanh menu và cửa sổ cài đặt |
| `FinderExtension/`, `FinderMenu.swift` | Tiện ích mở rộng Finder (menu con “Chuyển đổi sang”) và xử lý yêu cầu của nó trong ứng dụng |

## Giấy phép của các thành phần đi kèm

FFmpeg được đưa vào dưới dạng một tệp thực thi riêng (`Contents/Helpers/ffmpeg`) theo giấy phép LGPL 2.1, được biên dịch kèm LAME (LGPL)
và libwebp (BSD). Văn bản giấy phép của chúng nằm trong `Contents/Resources/Licenses`; script biên dịch chính xác là
`scripts/build-ffmpeg.sh`.
