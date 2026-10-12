<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · **Italiano** · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Un'app per la barra dei menu di macOS: cambia l'estensione di un file nel Finder e cambierà anche il suo formato.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Icona](../Resources/AppIcon.png)

## Installazione

Scarica **RenameConvert.dmg** dall'[ultima release](https://github.com/Kohinor46/RenameConvert/releases/latest)
e trascina l'app in Applicazioni. Richiede macOS 15 o successivo, Apple Silicon o Intel.

L'app non è autenticata da Apple (notarizzata), quindi macOS blocca il primo avvio: clic destro sull'app → **Apri**
(oppure **Apri comunque** in Impostazioni di Sistema → Privacy e sicurezza).

## Sostieni il progetto

RenameConvert è gratuito. Se ti fa risparmiare tempo, puoi sostenerne lo sviluppo:

- **Carta bancaria (banche russe):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, solo rete TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Invia solo USDT sulla rete TON: altre monete o reti potrebbero andare perse.

Le stesse opzioni, con un codice QR, sono nell'app: menu → "Sostieni il progetto ♥…".

## Funzionalità

| Categoria | Da | A |
|---|---|---|
| Immagini | jpg, png, heic, webp, gif, tiff, bmp, RAW e altri | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · fotogramma (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animato) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documenti | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → immagine (prima pagina) |
| Dati | json, plist | json, plist |
| Archivi | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | gli stessi |

I formati che macOS non gestisce da solo (WebP, MP3, MKV, AVI, WebM, OGG…) vengono convertiti dal
**FFmpeg 7.1** integrato (LGPL 2.1, con LAME e libwebp). Viene compilato dai sorgenti ufficiali tramite `scripts/build-ffmpeg.sh`,
con verifica SHA-256, e dipende solo dalle librerie di sistema.

**Menu contestuale del Finder:** clic destro su un file (o più file) → **Converti in** → scegli un formato.
Il file viene convertito subito, come se ne avessi cambiato l’estensione. L’estensione del Finder si attiva al primo avvio;
puoi disattivarla in Impostazioni di Sistema → Generali → Elementi login ed estensioni (o dall’app: Impostazioni → «Impostazioni estensioni del Finder…»).

**Regole.** Per ogni coppia "da → a" (un'estensione, una categoria o "qualsiasi") scegli cosa succede:
chiedere prima, convertire subito o non convertire, e se conservare l'originale.
Vince la regola più specifica; per impostazione predefinita i video sono su "Chiedi" e tutto il resto su "Converti subito".

**Pannello di conferma:** compare nell'angolo in alto a destra; modifica i parametri di questa specifica conversione
e ricorda la scelta per questa coppia di estensioni.

**Parametri:** qualità JPEG/HEIC/AVIF/WebP; per i video: codec (senza ricodifica / H.264 / HEVC),
risoluzione (4K…480p, mai ingrandita), frequenza fotogrammi, rimozione della posizione e dei metadati personali;
frequenza fotogrammi e larghezza delle GIF; bitrate AAC/MP3; formato pagina PDF.

**Aggiornamenti:** un pulsante "Verifica aggiornamenti" e un controllo automatico giornaliero su
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). L'aggiornamento viene scaricato,
verificato tramite SHA-256 e firma del codice, e installato con un riavvio dell'app.

**Segnalazione bug:** menu → "Segnala un bug…" (o il pulsante in una notifica di errore) crea un'email per lo
sviluppatore con la tua descrizione, le informazioni di sistema e il log dell'app in allegato. Log:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 lingue:** inglese, russo, tedesco, francese, spagnolo, italiano, portoghese (Brasile), olandese, polacco,
ucraino, ceco, svedese, turco, arabo, ebraico, hindi, indonesiano, vietnamita, thailandese, giapponese, coreano,
cinese (semplificato e tradizionale).

**Inoltre:** cartelle monitorate ed esclusioni, avanzamento e annullamento nella barra dei menu, cronologia con "Ripristina originale",
originali spostati nel Cestino, notifiche, apertura al login. Tutto avviene in locale: i file non lasciano mai il tuo Mac.

## Compilazione

Richiede macOS 15+ e i Command Line Tools (`xcode-select --install`). Xcode è facoltativo,
ma il progetto si apre al suo interno come pacchetto Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universale: Apple Silicon + Intel); compila FFmpeg alla prima esecuzione (~15 min)
./build.sh install    # installa in ~/Applications e avvia
./build.sh dist       # build/RenameConvert.zip (per l'aggiornamento automatico) e build/RenameConvert.dmg
./build.sh release    # dist + pubblica la release v<version> su GitHub
```

Traduzioni: `scripts/extract-strings.py` raccoglie le stringhe dell'interfaccia in `Resources/Localization/keys.json`;
`--check` verifica che ogni lingua contenga tutte le stringhe con i segnaposto corrispondenti.
Video promozionali: `scripts/promo/make-promo.sh` (voce narrante con `say`, fotogrammi SwiftUI, uniti con FFmpeg).

## Architettura

| File | Scopo |
|---|---|
| `RenameWatcher.swift` | FSEvents: intercetta le coppie "vecchio nome → nuovo nome" |
| `Formats.swift` | Registro dei formati: quale motore gestisce una coppia di estensioni |
| `Rules.swift` | Regole e parametri di conversione |
| `Pipeline.swift` | Cartella di lavoro, esecuzione del motore, originale nel Cestino, sostituzione atomica |
| `Engines/ImageEngine.swift` | Immagini (ImageIO), PDF → immagine |
| `Engines/MediaEngine.swift` | Video, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documenti (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archivi (bsdtar), errori comuni |
| `Engines/FFmpegEngine.swift` | FFmpeg integrato: WebP, MP3, MKV, AVI, WebM, OGG, GIF con palette |
| `Updater.swift` | Verifica e installazione degli aggiornamenti da GitHub Releases |
| `BugReport.swift`, `Log.swift` | Segnalazione bug via email, log dell'app |
| `AppModel.swift` | Impostazioni, coda, richieste, cronologia, notifiche |
| `AskPanel.swift`, `ParamsForm.swift` | Pannello di conferma e modulo dei parametri |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu nella barra dei menu e finestra delle impostazioni |
| `FinderExtension/`, `FinderMenu.swift` | Estensione del Finder (sottomenu «Converti in») e gestione delle sue richieste nell’app |

## Licenza dei componenti inclusi

FFmpeg è incluso come eseguibile separato (`Contents/Helpers/ffmpeg`) con licenza LGPL 2.1, compilato con LAME (LGPL)
e libwebp (BSD). I testi delle loro licenze si trovano in `Contents/Resources/Licenses`; lo script di compilazione esatto è
`scripts/build-ffmpeg.sh`.
