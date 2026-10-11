<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · **Nederlands** · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Een menubalk-app voor macOS: wijzig de extensie van een bestand in de Finder en het formaat verandert mee.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Icoon](../Resources/AppIcon.png)

## Installatie

Download **RenameConvert.dmg** van de [nieuwste release](https://github.com/Kohinor46/RenameConvert/releases/latest)
en sleep de app naar de map Apps. Vereist macOS 15 of nieuwer, Apple Silicon of Intel.

De app is niet genotariseerd, dus macOS blokkeert de eerste keer openen: klik met de rechtermuisknop op de app → **Open**
(of **Open toch** in Systeeminstellingen → Privacy en beveiliging).

## Steun het project

RenameConvert is gratis. Bespaart het je tijd, dan kun je de ontwikkeling steunen:

- **Bankpas (Russische banken):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, alleen TON-netwerk:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Stuur alleen USDT via het TON-netwerk — andere munten of netwerken kunnen verloren gaan.

Dezelfde opties, met een QR-code, vind je in de app: menu → "Steun het project ♥…".

## Functies

| Categorie | Van | Naar |
|---|---|---|
| Afbeeldingen | jpg, png, heic, webp, gif, tiff, bmp, RAW en meer | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · frame (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (geanimeerd) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documenten | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → afbeelding (eerste pagina) |
| Gegevens | json, plist | json, plist |
| Archieven | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | dezelfde |

Formaten die macOS zelf niet aankan (WebP, MP3, MKV, AVI, WebM, OGG…) worden geconverteerd door de ingebouwde
**FFmpeg 7.1** (LGPL 2.1, met LAME en libwebp). Deze wordt door `scripts/build-ffmpeg.sh` gebouwd uit de officiële broncode,
met SHA-256-controles, en is alleen afhankelijk van systeembibliotheken.

**Regels.** Voor elk paar "van → naar" (een extensie, een categorie of "willekeurig") bepaal je wat er gebeurt:
eerst vragen, direct converteren of niet converteren — en of het origineel bewaard blijft.
De meest specifieke regel wint; standaard staat video op "Vraag" en al het andere op "Converteer direct".

**Bevestigingspaneel** verschijnt in de rechterbovenhoek: pas de parameters voor deze specifieke conversie aan
en onthoud de keuze voor dit paar extensies.

**Parameters:** kwaliteit voor JPEG/HEIC/AVIF/WebP; voor video — codec (zonder hercodering / H.264 / HEVC),
resolutie (4K…480p, nooit opgeschaald), framerate, verwijderen van locatie- en persoonlijke metadata;
framerate en breedte van GIF's; bitrate van AAC/MP3; paginaformaat van PDF.

**Updates:** een knop "Zoek naar updates" en een automatische dagelijkse controle via
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). De update wordt gedownload,
gecontroleerd op SHA-256 en codesignatuur, en geïnstalleerd met een herstart.

**Foutmelding:** menu → "Meld een fout…" (of de knop in een foutmelding) maakt een e-mail aan de
ontwikkelaar aan met je beschrijving, systeeminformatie en het app-logbestand als bijlage. Logbestand:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 talen:** Engels, Russisch, Duits, Frans, Spaans, Italiaans, Portugees (Brazilië), Nederlands, Pools,
Oekraïens, Tsjechisch, Zweeds, Turks, Arabisch, Hebreeuws, Hindi, Indonesisch, Vietnamees, Thai, Japans, Koreaans,
Chinees (vereenvoudigd en traditioneel).

**Verder:** bewaakte mappen en uitzonderingen, voortgang en annuleren in de menubalk, geschiedenis met "Herstel origineel",
originelen naar de prullenmand, meldingen, openen bij inloggen. Alles draait lokaal — bestanden verlaten je Mac nooit.

## Bouwen

Vereist macOS 15+ en de Command Line Tools (`xcode-select --install`). Xcode is optioneel,
maar het project opent daarin als Swift-pakket (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universeel: Apple Silicon + Intel); bouwt FFmpeg bij de eerste keer (~15 min)
./build.sh install    # installeren in ~/Applications en starten
./build.sh dist       # build/RenameConvert.zip (voor automatische updates) en build/RenameConvert.dmg
./build.sh release    # dist + release v<versie> publiceren op GitHub
```

Vertalingen: `scripts/extract-strings.py` verzamelt de UI-teksten in `Resources/Localization/keys.json`;
`--check` controleert of elke taal alle teksten heeft met overeenkomende placeholders.
Promovideo's: `scripts/promo/make-promo.sh` (voice-over met `say`, SwiftUI-frames, samengevoegd met FFmpeg).

## Architectuur

| Bestand | Doel |
|---|---|
| `RenameWatcher.swift` | FSEvents: vangt paren "oude naam → nieuwe naam" op |
| `Formats.swift` | Formatenregister: welke engine een paar extensies afhandelt |
| `Rules.swift` | Regels en conversieparameters |
| `Pipeline.swift` | Werkmap, uitvoeren van de engine, origineel naar de prullenmand, atomaire vervanging |
| `Engines/ImageEngine.swift` | Afbeeldingen (ImageIO), PDF → afbeelding |
| `Engines/MediaEngine.swift` | Video, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documenten (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archieven (bsdtar), gedeelde fouten |
| `Engines/FFmpegEngine.swift` | Ingebouwde FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIF's met palet |
| `Updater.swift` | Updates zoeken en installeren vanuit GitHub Releases |
| `BugReport.swift`, `Log.swift` | Foutmelding per e-mail, app-logbestand |
| `AppModel.swift` | Instellingen, wachtrij, vragen, geschiedenis, meldingen |
| `AskPanel.swift`, `ParamsForm.swift` | Bevestigingspaneel en parameterformulier |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menubalkmenu en instellingenvenster |

## Licentie van meegeleverde componenten

FFmpeg wordt meegeleverd als een afzonderlijk uitvoerbaar bestand (`Contents/Helpers/ffmpeg`) onder LGPL 2.1, gebouwd met LAME (LGPL)
en libwebp (BSD). Hun licentieteksten staan in `Contents/Resources/Licenses`; het exacte buildscript is
`scripts/build-ffmpeg.sh`.
