<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · **繁體中文**
<!-- /languages -->

# RenameConvert

一款 macOS 選單列 App：在 Finder 中更改檔案的副檔名，檔案格式也會跟著轉換。
`photo.heic` → `photo.jpg`、`clip.mov` → `clip.mp4`、`clip.mov` → `clip.gif`、`report.docx` → `report.pdf`。

![圖像](../Resources/AppIcon.png)

## 安裝

從[最新版本](https://github.com/Kohinor46/RenameConvert/releases/latest)下載 **RenameConvert.dmg**，
然後將 App 拖移到「應用程式」檔案夾。需要 macOS 15 或以上版本，支援 Apple Silicon 和 Intel。

此 App 未經公證，因此 macOS 會阻擋第一次開啟：在 App 上按右鍵 → **打開**
（或在「系統設定」→「隱私權與安全性」中按一下 **強制打開**）。

## 功能

| 類別 | 來源格式 | 目標格式 |
|---|---|---|
| 影像 | jpg、png、heic、webp、gif、tiff、bmp、RAW 等 | jpg、png、heic、avif、**webp**、gif、tiff、bmp、jp2、ico、icns、psd、tga、pdf |
| 影片 | mov、mp4、m4v、3gp、**mkv、avi、webm、flv、wmv、mpg、ts、mts、ogv** | mov、mp4、m4v、**mkv** · **gif** · 音訊（m4a、**mp3**、wav、aiff、caf、flac） · 影格（jpg、png…） |
| GIF | gif | mp4、mov、m4v、webp（動畫） |
| 音訊 | mp3、m4a、aac、wav、aiff、caf、flac、**ogg、opus、wma、ac3、amr、ape** | m4a、**mp3**、wav、aiff、caf、flac |
| 文件 | txt、rtf、html、docx、doc、odt、webarchive、pdf | txt、rtf、html、docx、doc、odt、pdf · PDF → 影像（第一頁） |
| 資料 | json、plist | json、plist |
| 封存檔 | zip、tar、tar.gz、tar.bz2、tar.xz、7z | 同上 |

macOS 本身無法處理的格式（WebP、MP3、MKV、AVI、WebM、OGG…）由內建的
**FFmpeg 7.1**（LGPL 2.1，包含 LAME 和 libwebp）進行轉換。它由 `scripts/build-ffmpeg.sh` 從官方原始碼建置，
經過 SHA-256 檢查，且僅依賴系統程式庫。

**規則。** 針對任何「來源 → 目標」組合（副檔名、類別或「任何」），你都可以選擇處理方式：
先詢問、立即轉換或不轉換，以及是否保留原始檔案。
最具體的規則優先；預設情況下，影片為「詢問」，其他所有類型為「立即轉換」。

**確認面板**會顯示在螢幕右上角：可以只針對這次轉換更改參數，
並記住這組副檔名的選擇。

**參數：** JPEG/HEIC/AVIF/WebP 品質；影片的編解碼器（不重新編碼 / H.264 / HEVC）、
解析度（4K…480p，絕不放大）、影格速率、移除位置與個人後設資料；
GIF 影格速率和寬度；AAC/MP3 位元率；PDF 頁面大小。

**更新：** 提供「檢查更新項目」按鈕，並每天自動檢查
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases)。更新下載後，
會透過 SHA-256 和程式碼簽名進行驗證，然後安裝並重新啟動 App。

**錯誤回報：** 選單 →「回報錯誤…」（或錯誤通知中的按鈕）會建立一封寄給開發者的電子郵件，
內含你的描述、系統資訊，並附上 App 記錄檔。記錄檔：
`~/Library/Logs/RenameConvert/RenameConvert.log`。

**23 種語言：** 英文、俄文、德文、法文、西班牙文、義大利文、葡萄牙文（巴西）、荷蘭文、波蘭文、
烏克蘭文、捷克文、瑞典文、土耳其文、阿拉伯文、希伯來文、印地文、印尼文、越南文、泰文、日文、韓文、
中文（簡體與繁體）。

**此外：** 監看檔案夾與排除項目、選單列中的進度顯示與取消、支援「復原原始檔案」的歷史記錄、
將原始檔案移到垃圾桶、通知、登入時開啟。所有處理皆在本機進行——檔案絕不會離開你的 Mac。

## 建置

需要 macOS 15 以上版本和 Command Line Tools（`xcode-select --install`）。Xcode 並非必要，
但可以在 Xcode 中將專案作為 Swift 套件開啟（`open Package.swift`）。

```bash
./build.sh            # build/RenameConvert.app（通用：Apple Silicon + Intel）；首次執行時會建置 FFmpeg（約 15 分鐘）
./build.sh install    # 安裝到 ~/Applications 並啟動
./build.sh dist       # build/RenameConvert.zip（用於自動更新）和 build/RenameConvert.dmg
./build.sh release    # dist + 在 GitHub 上發佈 v<version> 版本
```

翻譯：`scripts/extract-strings.py` 會將介面字串收集到 `Resources/Localization/keys.json`；
`--check` 會檢查每種語言是否包含所有字串且預留位置相符。
宣傳影片：`scripts/promo/make-promo.sh`（使用 `say` 配音、SwiftUI 畫面，以 FFmpeg 合併）。

## 架構

| 檔案 | 用途 |
|---|---|
| `RenameWatcher.swift` | FSEvents：捕捉「舊名稱 → 新名稱」組合 |
| `Formats.swift` | 格式登錄表：由哪個引擎處理某組副檔名 |
| `Rules.swift` | 規則與轉換參數 |
| `Pipeline.swift` | 工作檔案夾、執行引擎、將原始檔案移到垃圾桶、原子性取代 |
| `Engines/ImageEngine.swift` | 影像（ImageIO）、PDF → 影像 |
| `Engines/MediaEngine.swift` | 影片、GIF、音訊（AVFoundation、afconvert） |
| `Engines/DocumentEngine.swift` | 文件（NSAttributedString、PDFKit、CoreText） |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist、封存檔（bsdtar）、共用錯誤 |
| `Engines/FFmpegEngine.swift` | 內建 FFmpeg：WebP、MP3、MKV、AVI、WebM、OGG、調色盤 GIF |
| `Updater.swift` | 從 GitHub Releases 檢查並安裝更新 |
| `BugReport.swift`、`Log.swift` | 透過電子郵件回報錯誤、App 記錄檔 |
| `AppModel.swift` | 設定、佇列、詢問提示、歷史記錄、通知 |
| `AskPanel.swift`、`ParamsForm.swift` | 確認面板與參數表單 |
| `RenameConvertApp.swift`、`SettingsView.swift` | 選單列選單與設定視窗 |

## 隨附元件的授權

FFmpeg 以獨立執行檔（`Contents/Helpers/ffmpeg`）的形式依 LGPL 2.1 授權隨附，建置時包含 LAME（LGPL）
和 libwebp（BSD）。其授權條款全文位於 `Contents/Resources/Licenses`；確切的建置指令碼為
`scripts/build-ffmpeg.sh`。
