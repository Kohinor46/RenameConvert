<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · **Čeština** · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Aplikace pro řádek nabídek macOS: změňte příponu souboru ve Finderu a změní se i jeho formát.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Ikona](../Resources/AppIcon.png)

## Instalace

Stáhněte **RenameConvert.dmg** z [nejnovějšího vydání](https://github.com/Kohinor46/RenameConvert/releases/latest)
a přetáhněte aplikaci do složky Aplikace. Vyžaduje macOS 15 nebo novější, Apple Silicon nebo Intel.

Aplikace není notarizovaná, proto macOS zablokuje první spuštění: klikněte na aplikaci pravým tlačítkem → **Otevřít**
(nebo **Přesto otevřít** v Nastavení systému → Soukromí a zabezpečení).

## Funkce

| Kategorie | Z | Do |
|---|---|---|
| Obrázky | jpg, png, heic, webp, gif, tiff, bmp, RAW a další | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · zvuk (m4a, **mp3**, wav, aiff, caf, flac) · snímek (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animovaný) |
| Zvuk | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Dokumenty | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → obrázek (první stránka) |
| Data | json, plist | json, plist |
| Archivy | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | totéž |

Formáty, které macOS sám nezvládne (WebP, MP3, MKV, AVI, WebM, OGG…), převádí vestavěný
**FFmpeg 7.1** (LGPL 2.1, s LAME a libwebp). Sestavuje se z oficiálních zdrojů skriptem `scripts/build-ffmpeg.sh`
s kontrolou SHA-256 a závisí pouze na systémových knihovnách.

**Pravidla.** Pro libovolnou dvojici „z → do“ (příponu, kategorii nebo „cokoli“) si zvolíte, co se stane:
nejdřív se zeptat, převést ihned, nebo nepřevádět — a zda ponechat originál.
Vyhrává nejkonkrétnější pravidlo; ve výchozím stavu je pro video nastaveno „Zeptat se“ a pro vše ostatní „Převést ihned“.

**Potvrzovací panel** se zobrazí v pravém horním rohu: upravte parametry právě tohoto převodu
a zapamatujte si rozhodnutí pro tuto dvojici přípon.

**Parametry:** kvalita JPEG/HEIC/AVIF/WebP; pro video — kodek (bez překódování / H.264 / HEVC),
rozlišení (4K…480p, nikdy se nezvětšuje), snímková frekvence, odstranění polohy a osobních metadat;
snímková frekvence a šířka GIF; datový tok AAC/MP3; velikost stránky PDF.

**Aktualizace:** tlačítko „Vyhledat aktualizace“ a automatická denní kontrola na
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Aktualizace se stáhne,
ověří pomocí SHA-256 a podpisu kódu a nainstaluje s novým spuštěním.

**Hlášení chyb:** nabídka → „Nahlásit chybu…“ (nebo tlačítko v oznámení o chybě) vytvoří e-mail
vývojáři s vaším popisem, informacemi o systému a přiloženým protokolem aplikace. Protokol:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 jazyků:** angličtina, ruština, němčina, francouzština, španělština, italština, portugalština (Brazílie), nizozemština, polština,
ukrajinština, čeština, švédština, turečtina, arabština, hebrejština, hindština, indonéština, vietnamština, thajština, japonština, korejština,
čínština (zjednodušená a tradiční).

**Dále:** sledované složky a výjimky, průběh a zrušení v řádku nabídek, historie s funkcí „Obnovit originál“,
přesun originálů do Koše, oznámení, spouštění po přihlášení. Vše běží lokálně — soubory nikdy neopustí váš Mac.

## Sestavení

Vyžaduje macOS 15+ a Command Line Tools (`xcode-select --install`). Xcode není nutný,
ale projekt v něm lze otevřít jako balíček Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (univerzální: Apple Silicon + Intel); při prvním spuštění sestaví FFmpeg (~15 min)
./build.sh install    # instalace do ~/Applications a spuštění
./build.sh dist       # build/RenameConvert.zip (pro automatické aktualizace) a build/RenameConvert.dmg
./build.sh release    # dist + zveřejnění vydání v<verze> na GitHubu
```

Překlady: `scripts/extract-strings.py` shromažďuje řetězce rozhraní do `Resources/Localization/keys.json`;
`--check` ověří, že každý jazyk obsahuje všechny řetězce s odpovídajícími zástupnými symboly.
Propagační videa: `scripts/promo/make-promo.sh` (namluvení pomocí `say`, snímky SwiftUI, sloučení pomocí FFmpeg).

## Architektura

| Soubor | Účel |
|---|---|
| `RenameWatcher.swift` | FSEvents: zachytává dvojice „starý název → nový název“ |
| `Formats.swift` | Registr formátů: který engine zpracuje danou dvojici přípon |
| `Rules.swift` | Pravidla a parametry převodu |
| `Pipeline.swift` | Pracovní složka, spuštění enginu, originál do Koše, atomické nahrazení |
| `Engines/ImageEngine.swift` | Obrázky (ImageIO), PDF → obrázek |
| `Engines/MediaEngine.swift` | Video, GIF, zvuk (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Dokumenty (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archivy (bsdtar), společné chyby |
| `Engines/FFmpegEngine.swift` | Vestavěný FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIF s paletou |
| `Updater.swift` | Vyhledání a instalace aktualizací z GitHub Releases |
| `BugReport.swift`, `Log.swift` | Hlášení chyb e-mailem, protokol aplikace |
| `AppModel.swift` | Nastavení, fronta, dotazy, historie, oznámení |
| `AskPanel.swift`, `ParamsForm.swift` | Potvrzovací panel a formulář parametrů |
| `RenameConvertApp.swift`, `SettingsView.swift` | Nabídka v řádku nabídek a okno nastavení |

## Licence přibalených komponent

FFmpeg je přiložen jako samostatný spustitelný soubor (`Contents/Helpers/ffmpeg`) pod licencí LGPL 2.1, sestavený s LAME (LGPL)
a libwebp (BSD). Texty jejich licencí jsou v `Contents/Resources/Licenses`; přesný sestavovací skript je
`scripts/build-ffmpeg.sh`.
