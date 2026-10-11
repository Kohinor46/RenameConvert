<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **简体中文** · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

一款 macOS 菜单栏应用：在 Finder 中更改文件扩展名，文件格式也会随之转换。
`photo.heic` → `photo.jpg`、`clip.mov` → `clip.mp4`、`clip.mov` → `clip.gif`、`report.docx` → `report.pdf`。

![图标](../Resources/AppIcon.png)

## 安装

从[最新版本](https://github.com/Kohinor46/RenameConvert/releases/latest)下载 **RenameConvert.dmg**，
然后将应用拖到“应用程序”文件夹。需要 macOS 15 或更高版本，支持 Apple Silicon 和 Intel。

该应用未经公证，因此 macOS 会阻止首次启动：右键点按应用 → **打开**
（或在“系统设置”→“隐私与安全性”中点按 **仍要打开**）。

## 功能

| 类别 | 源格式 | 目标格式 |
|---|---|---|
| 图像 | jpg、png、heic、webp、gif、tiff、bmp、RAW 等 | jpg、png、heic、avif、**webp**、gif、tiff、bmp、jp2、ico、icns、psd、tga、pdf |
| 视频 | mov、mp4、m4v、3gp、**mkv、avi、webm、flv、wmv、mpg、ts、mts、ogv** | mov、mp4、m4v、**mkv** · **gif** · 音频（m4a、**mp3**、wav、aiff、caf、flac） · 帧（jpg、png…） |
| GIF | gif | mp4、mov、m4v、webp（动画） |
| 音频 | mp3、m4a、aac、wav、aiff、caf、flac、**ogg、opus、wma、ac3、amr、ape** | m4a、**mp3**、wav、aiff、caf、flac |
| 文稿 | txt、rtf、html、docx、doc、odt、webarchive、pdf | txt、rtf、html、docx、doc、odt、pdf · PDF → 图像（第一页） |
| 数据 | json、plist | json、plist |
| 归档 | zip、tar、tar.gz、tar.bz2、tar.xz、7z | 同上 |

macOS 本身无法处理的格式（WebP、MP3、MKV、AVI、WebM、OGG…）由内置的
**FFmpeg 7.1**（LGPL 2.1，包含 LAME 和 libwebp）进行转换。它由 `scripts/build-ffmpeg.sh` 从官方源码构建，
经过 SHA-256 校验，且仅依赖系统库。

**规则。** 对于任意“源 → 目标”组合（扩展名、类别或“任意”），你都可以选择处理方式：
先询问、立即转换或不转换，以及是否保留原件。
最具体的规则优先生效；默认情况下，视频为“询问”，其他所有类型为“立即转换”。

**确认面板**显示在屏幕右上角：可以仅针对本次转换更改参数，
并记住针对这对扩展名的选择。

**参数：** JPEG/HEIC/AVIF/WebP 质量；视频的编解码器（不重新编码 / H.264 / HEVC）、
分辨率（4K…480p，绝不放大）、帧率、移除位置和个人元数据；
GIF 帧率和宽度；AAC/MP3 比特率；PDF 页面尺寸。

**更新：** 提供“检查更新”按钮，并每天自动检查
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases)。更新下载后，
会通过 SHA-256 和代码签名进行验证，然后安装并重新启动应用。

**错误报告：** 菜单 →“报告错误…”（或错误通知中的按钮）会创建一封发给开发者的邮件，
其中包含你的描述、系统信息，并附上应用日志。日志：
`~/Library/Logs/RenameConvert/RenameConvert.log`。

**23 种语言：** 英语、俄语、德语、法语、西班牙语、意大利语、葡萄牙语（巴西）、荷兰语、波兰语、
乌克兰语、捷克语、瑞典语、土耳其语、阿拉伯语、希伯来语、印地语、印度尼西亚语、越南语、泰语、日语、韩语、
中文（简体和繁体）。

**此外：** 监视文件夹和排除项、菜单栏中的进度显示与取消、支持“恢复原件”的历史记录、
将原件移到废纸篓、通知、登录时启动。一切均在本地运行——文件永远不会离开你的 Mac。

## 构建

需要 macOS 15+ 和 Command Line Tools（`xcode-select --install`）。Xcode 不是必需的，
但可以在 Xcode 中将项目作为 Swift 包打开（`open Package.swift`）。

```bash
./build.sh            # build/RenameConvert.app（通用：Apple Silicon + Intel）；首次运行时构建 FFmpeg（约 15 分钟）
./build.sh install    # 安装到 ~/Applications 并启动
./build.sh dist       # build/RenameConvert.zip（用于自动更新）和 build/RenameConvert.dmg
./build.sh release    # dist + 在 GitHub 上发布 v<version> 版本
```

翻译：`scripts/extract-strings.py` 将界面字符串收集到 `Resources/Localization/keys.json`；
`--check` 检查每种语言是否包含所有字符串且占位符一致。
宣传视频：`scripts/promo/make-promo.sh`（使用 `say` 配音，SwiftUI 渲染画面，FFmpeg 合成）。

## 架构

| 文件 | 用途 |
|---|---|
| `RenameWatcher.swift` | FSEvents：捕获“旧名称 → 新名称”对 |
| `Formats.swift` | 格式注册表：由哪个引擎处理某对扩展名 |
| `Rules.swift` | 规则和转换参数 |
| `Pipeline.swift` | 工作文件夹、运行引擎、将原件移到废纸篓、原子替换 |
| `Engines/ImageEngine.swift` | 图像（ImageIO）、PDF → 图像 |
| `Engines/MediaEngine.swift` | 视频、GIF、音频（AVFoundation、afconvert） |
| `Engines/DocumentEngine.swift` | 文稿（NSAttributedString、PDFKit、CoreText） |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist、归档（bsdtar）、通用错误 |
| `Engines/FFmpegEngine.swift` | 内置 FFmpeg：WebP、MP3、MKV、AVI、WebM、OGG、调色板 GIF |
| `Updater.swift` | 从 GitHub Releases 检查并安装更新 |
| `BugReport.swift`、`Log.swift` | 通过邮件报告错误、应用日志 |
| `AppModel.swift` | 设置、队列、询问、历史记录、通知 |
| `AskPanel.swift`、`ParamsForm.swift` | 确认面板和参数表单 |
| `RenameConvertApp.swift`、`SettingsView.swift` | 菜单栏菜单和设置窗口 |

## 内置组件的许可证

FFmpeg 作为独立的可执行文件（`Contents/Helpers/ffmpeg`）以 LGPL 2.1 许可证随附，构建时包含 LAME（LGPL）
和 libwebp（BSD）。它们的许可证文本位于 `Contents/Resources/Licenses`；确切的构建脚本为
`scripts/build-ffmpeg.sh`。
