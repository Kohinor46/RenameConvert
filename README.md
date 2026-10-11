<!-- languages -->
🌐 **English** · [Русский](docs/README.ru.md) · [Deutsch](docs/README.de.md) · [Français](docs/README.fr.md) · [Español](docs/README.es.md) · [Italiano](docs/README.it.md) · [Português (Brasil)](docs/README.pt-BR.md) · [Nederlands](docs/README.nl.md) · [Polski](docs/README.pl.md) · [Українська](docs/README.uk.md) · [Čeština](docs/README.cs.md) · [Svenska](docs/README.sv.md) · [Türkçe](docs/README.tr.md) · [العربية](docs/README.ar.md) · [עברית](docs/README.he.md) · [हिन्दी](docs/README.hi.md) · [Bahasa Indonesia](docs/README.id.md) · [Tiếng Việt](docs/README.vi.md) · [ไทย](docs/README.th.md) · [日本語](docs/README.ja.md) · [한국어](docs/README.ko.md) · [简体中文](docs/README.zh-Hans.md) · [繁體中文](docs/README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

A macOS menu bar app: change a file's extension in Finder and its format changes too.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Icon](Resources/AppIcon.png)

## Install

Download **RenameConvert.dmg** from the [latest release](https://github.com/Kohinor46/RenameConvert/releases/latest)
and drag the app to Applications. Requires macOS 15 or later, Apple Silicon or Intel.

The app is not notarized, so macOS blocks the first launch: right-click the app → **Open**
(or **Open Anyway** in System Settings → Privacy & Security).

## Features

| Category | From | To |
|---|---|---|
| Images | jpg, png, heic, webp, gif, tiff, bmp, RAW and more | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · frame (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animated) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documents | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → image (first page) |
| Data | json, plist | json, plist |
| Archives | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | the same |

Formats that macOS can't handle on its own (WebP, MP3, MKV, AVI, WebM, OGG…) are converted by the built-in
**FFmpeg 7.1** (LGPL 2.1, with LAME and libwebp). It is built from official sources by `scripts/build-ffmpeg.sh`,
with SHA-256 checks, and depends only on system libraries.

**Rules.** For any "from → to" pair (an extension, a category, or "any") you choose what happens:
ask first, convert right away, or don't convert — and whether to keep the original.
The most specific rule wins; by default video is "Ask" and everything else is "Convert immediately".

**Confirmation panel** appears in the top-right corner: change the parameters for this particular conversion
and remember the decision for this pair of extensions.

**Parameters:** JPEG/HEIC/AVIF/WebP quality; for video — codec (no re-encoding / H.264 / HEVC),
resolution (4K…480p, never upscaled), frame rate, removal of location and personal metadata;
GIF frame rate and width; AAC/MP3 bitrate; PDF page size.

**Updates:** a "Check for Updates" button and an automatic daily check against
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). The update is downloaded,
verified by SHA-256 and code signature, and installed with a relaunch.

**Bug report:** menu → "Report a Bug…" (or the button in an error notification) creates an email to the
developer with your description, system info, and the app log attached. Log:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 languages:** English, Russian, German, French, Spanish, Italian, Portuguese (Brazil), Dutch, Polish,
Ukrainian, Czech, Swedish, Turkish, Arabic, Hebrew, Hindi, Indonesian, Vietnamese, Thai, Japanese, Korean,
Chinese (Simplified and Traditional).

**Also:** watched folders and exclusions, progress and cancel in the menu bar, history with "Restore Original",
originals moved to the Trash, notifications, launch at login. Everything runs locally — files never leave your Mac.

## Building

Requires macOS 15+ and the Command Line Tools (`xcode-select --install`). Xcode is optional,
but the project opens in it as a Swift package (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universal: Apple Silicon + Intel); builds FFmpeg on first run (~15 min)
./build.sh install    # install to ~/Applications and launch
./build.sh dist       # build/RenameConvert.zip (for auto-update) and build/RenameConvert.dmg
./build.sh release    # dist + publish release v<version> on GitHub
```

Translations: `scripts/extract-strings.py` collects UI strings into `Resources/Localization/keys.json`;
`--check` verifies that every language has every string with matching placeholders.
Promo videos: `scripts/promo/make-promo.sh` (voice-over with `say`, SwiftUI frames, muxed with FFmpeg).

## Architecture

| File | Purpose |
|---|---|
| `RenameWatcher.swift` | FSEvents: catches "old name → new name" pairs |
| `Formats.swift` | Format registry: which engine handles a pair of extensions |
| `Rules.swift` | Rules and conversion parameters |
| `Pipeline.swift` | Work folder, running the engine, original to the Trash, atomic replace |
| `Engines/ImageEngine.swift` | Images (ImageIO), PDF → image |
| `Engines/MediaEngine.swift` | Video, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documents (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archives (bsdtar), shared errors |
| `Engines/FFmpegEngine.swift` | Built-in FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, palette GIFs |
| `Updater.swift` | Checking for and installing updates from GitHub Releases |
| `BugReport.swift`, `Log.swift` | Bug report by email, app log |
| `AppModel.swift` | Settings, queue, prompts, history, notifications |
| `AskPanel.swift`, `ParamsForm.swift` | Confirmation panel and parameters form |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu bar menu and settings window |

## License of bundled components

FFmpeg is included as a separate executable (`Contents/Helpers/ffmpeg`) under LGPL 2.1, built with LAME (LGPL)
and libwebp (BSD). Their license texts are in `Contents/Resources/Licenses`; the exact build script is
`scripts/build-ffmpeg.sh`.
