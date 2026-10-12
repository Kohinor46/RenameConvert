<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · **Deutsch** · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Eine App für die macOS-Menüleiste: Ändere die Dateiendung im Finder, und das Format ändert sich gleich mit.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Symbol](../Resources/AppIcon.png)

## Installation

Lade **RenameConvert.dmg** aus dem [neuesten Release](https://github.com/Kohinor46/RenameConvert/releases/latest) herunter
und ziehe die App in den Ordner „Programme“. Voraussetzungen: macOS 15 oder neuer, Apple Silicon oder Intel.

Die App ist nicht notarisiert, daher blockiert macOS den ersten Start: Rechtsklick auf die App → **Öffnen**
(oder **Trotzdem öffnen** unter Systemeinstellungen → Datenschutz & Sicherheit).

## Projekt unterstützen

RenameConvert ist kostenlos. Wenn es dir Zeit spart, kannst du die Entwicklung unterstützen:

- **Bankkarte (russische Banken):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, nur TON-Netzwerk:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Sende nur USDT im TON-Netzwerk – andere Coins oder Netzwerke können verloren gehen.

Dieselben Optionen mit QR-Code findest du in der App: Menü → „Projekt unterstützen ♥ …“.

## Funktionen

| Kategorie | Von | Nach |
|---|---|---|
| Bilder | jpg, png, heic, webp, gif, tiff, bmp, RAW und mehr | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · Audio (m4a, **mp3**, wav, aiff, caf, flac) · Einzelbild (jpg, png …) |
| GIF | gif | mp4, mov, m4v, webp (animiert) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Dokumente | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → Bild (erste Seite) |
| Daten | json, plist | json, plist |
| Archive | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | dieselben |

Formate, die macOS nicht selbst verarbeiten kann (WebP, MP3, MKV, AVI, WebM, OGG …), werden vom integrierten
**FFmpeg 7.1** (LGPL 2.1, mit LAME und libwebp) konvertiert. Es wird von `scripts/build-ffmpeg.sh` aus den offiziellen Quellen
mit SHA-256-Prüfung gebaut und hängt nur von Systembibliotheken ab.

**Finder-Kontextmenü:** Rechtsklick auf eine Datei (oder mehrere) → **Konvertieren in** → Format wählen.
Die Datei wird sofort konvertiert, als hättest du die Endung geändert. Die Finder-Erweiterung wird beim ersten Start aktiviert;
du kannst sie in den Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen ausschalten (oder in der App: Einstellungen → „Finder-Erweiterungen einrichten…“).

**Regeln.** Für jedes Paar „von → nach“ (eine Endung, eine Kategorie oder „beliebig“) legst du fest, was passiert:
erst fragen, sofort konvertieren oder nicht konvertieren – und ob das Original behalten wird.
Die spezifischste Regel gewinnt; standardmäßig gilt für Video „Fragen“ und für alles andere „Sofort konvertieren“.

**Bestätigungsfenster** erscheint in der oberen rechten Ecke: Passe die Parameter für genau diese Konvertierung an
und merke dir die Entscheidung für dieses Endungspaar.

**Parameter:** Qualität für JPEG/HEIC/AVIF/WebP; für Video – Codec (ohne Neucodierung / H.264 / HEVC),
Auflösung (4K…480p, niemals hochskaliert), Bildrate, Entfernen von Standort- und persönlichen Metadaten;
Bildrate und Breite für GIF; Bitrate für AAC/MP3; Seitenformat für PDF.

**Updates:** eine Schaltfläche „Nach Updates suchen“ und eine automatische tägliche Prüfung über
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Das Update wird heruntergeladen,
per SHA-256 und Codesignatur geprüft und mit einem Neustart installiert.

**Fehlerbericht:** Menü → „Fehler melden …“ (oder die Schaltfläche in einer Fehlermitteilung) erstellt eine E-Mail an den
Entwickler mit deiner Beschreibung, Systeminformationen und dem App-Protokoll im Anhang. Protokoll:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 Sprachen:** Englisch, Russisch, Deutsch, Französisch, Spanisch, Italienisch, Portugiesisch (Brasilien), Niederländisch, Polnisch,
Ukrainisch, Tschechisch, Schwedisch, Türkisch, Arabisch, Hebräisch, Hindi, Indonesisch, Vietnamesisch, Thailändisch, Japanisch, Koreanisch,
Chinesisch (vereinfacht und traditionell).

**Außerdem:** überwachte Ordner und Ausnahmen, Fortschritt und Abbrechen in der Menüleiste, Verlauf mit „Original wiederherstellen“,
Originale werden in den Papierkorb verschoben, Mitteilungen, Start bei der Anmeldung. Alles läuft lokal – deine Dateien verlassen nie deinen Mac.

## Bauen

Voraussetzungen: macOS 15+ und die Command Line Tools (`xcode-select --install`). Xcode ist optional,
aber das Projekt lässt sich darin als Swift-Paket öffnen (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (Universal: Apple Silicon + Intel); baut FFmpeg beim ersten Durchlauf (~15 Min.)
./build.sh install    # in ~/Applications installieren und starten
./build.sh dist       # build/RenameConvert.zip (für Auto-Update) und build/RenameConvert.dmg
./build.sh release    # dist + Release v<version> auf GitHub veröffentlichen
```

Übersetzungen: `scripts/extract-strings.py` sammelt die UI-Strings in `Resources/Localization/keys.json`;
`--check` prüft, ob jede Sprache alle Strings mit passenden Platzhaltern enthält.
Promo-Videos: `scripts/promo/make-promo.sh` (Sprachausgabe mit `say`, SwiftUI-Frames, mit FFmpeg zusammengeführt).

## Architektur

| Datei | Zweck |
|---|---|
| `RenameWatcher.swift` | FSEvents: erfasst Paare „alter Name → neuer Name“ |
| `Formats.swift` | Formatregister: welche Engine ein Endungspaar verarbeitet |
| `Rules.swift` | Regeln und Konvertierungsparameter |
| `Pipeline.swift` | Arbeitsordner, Ausführen der Engine, Original in den Papierkorb, atomares Ersetzen |
| `Engines/ImageEngine.swift` | Bilder (ImageIO), PDF → Bild |
| `Engines/MediaEngine.swift` | Video, GIF, Audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Dokumente (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, Archive (bsdtar), gemeinsame Fehler |
| `Engines/FFmpegEngine.swift` | Integriertes FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIFs mit Palette |
| `Updater.swift` | Suchen und Installieren von Updates aus GitHub Releases |
| `BugReport.swift`, `Log.swift` | Fehlerbericht per E-Mail, App-Protokoll |
| `AppModel.swift` | Einstellungen, Warteschlange, Rückfragen, Verlauf, Mitteilungen |
| `AskPanel.swift`, `ParamsForm.swift` | Bestätigungsfenster und Parameterformular |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menü in der Menüleiste und Einstellungsfenster |
| `FinderExtension/`, `FinderMenu.swift` | Finder-Erweiterung (Untermenü „Konvertieren in“) und Verarbeitung ihrer Anfragen in der App |

## Lizenz der mitgelieferten Komponenten

FFmpeg ist als separates Programm (`Contents/Helpers/ffmpeg`) unter LGPL 2.1 enthalten, gebaut mit LAME (LGPL)
und libwebp (BSD). Ihre Lizenztexte befinden sich in `Contents/Resources/Licenses`; das genaue Build-Skript ist
`scripts/build-ffmpeg.sh`.
