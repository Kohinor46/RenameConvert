<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · **Polski** · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Aplikacja dla paska menu macOS: zmień rozszerzenie pliku w Finderze, a zmieni się także jego format.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Ikona](../Resources/AppIcon.png)

## Instalacja

Pobierz **RenameConvert.dmg** z [najnowszego wydania](https://github.com/Kohinor46/RenameConvert/releases/latest)
i przeciągnij aplikację do folderu Aplikacje. Wymaga macOS 15 lub nowszego, Apple Silicon lub Intel.

Aplikacja nie jest notaryzowana, więc macOS blokuje pierwsze uruchomienie: kliknij aplikację prawym przyciskiem → **Otwórz**
(lub **Otwórz mimo to** w Ustawieniach systemowych → Prywatność i ochrona).

## Funkcje

| Kategoria | Z | Do |
|---|---|---|
| Obrazy | jpg, png, heic, webp, gif, tiff, bmp, RAW i inne | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Wideo | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · klatka (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animowany) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Dokumenty | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → obraz (pierwsza strona) |
| Dane | json, plist | json, plist |
| Archiwa | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | te same |

Formaty, których macOS nie obsługuje samodzielnie (WebP, MP3, MKV, AVI, WebM, OGG…), konwertuje wbudowany
**FFmpeg 7.1** (LGPL 2.1, z LAME i libwebp). Jest budowany z oficjalnych źródeł przez `scripts/build-ffmpeg.sh`,
z weryfikacją SHA-256, i zależy wyłącznie od bibliotek systemowych.

**Reguły.** Dla każdej pary „z → do” (rozszerzenie, kategoria lub „dowolne”) wybierasz, co ma się stać:
najpierw zapytać, od razu przekonwertować lub nie konwertować — oraz czy zachować oryginał.
Wygrywa najbardziej szczegółowa reguła; domyślnie dla wideo ustawione jest „Pytaj”, a dla wszystkiego innego „Konwertuj od razu”.

**Panel potwierdzenia** pojawia się w prawym górnym rogu: zmień parametry tej konkretnej konwersji
i zapamiętaj decyzję dla tej pary rozszerzeń.

**Parametry:** jakość JPEG/HEIC/AVIF/WebP; dla wideo — kodek (bez ponownego kodowania / H.264 / HEVC),
rozdzielczość (4K…480p, nigdy nie jest zwiększana), liczba klatek na sekundę, usuwanie lokalizacji i metadanych osobistych;
liczba klatek i szerokość GIF; przepływność AAC/MP3; rozmiar strony PDF.

**Uaktualnienia:** przycisk „Sprawdź uaktualnienia” oraz automatyczne codzienne sprawdzanie w
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Uaktualnienie jest pobierane,
weryfikowane za pomocą SHA-256 i podpisu kodu, a następnie instalowane z ponownym uruchomieniem.

**Zgłaszanie błędów:** menu → „Zgłoś błąd…” (lub przycisk w powiadomieniu o błędzie) tworzy wiadomość e-mail do
dewelopera z Twoim opisem, informacjami o systemie i załączonym dziennikiem aplikacji. Dziennik:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 języki:** angielski, rosyjski, niemiecki, francuski, hiszpański, włoski, portugalski (Brazylia), niderlandzki, polski,
ukraiński, czeski, szwedzki, turecki, arabski, hebrajski, hindi, indonezyjski, wietnamski, tajski, japoński, koreański,
chiński (uproszczony i tradycyjny).

**Ponadto:** obserwowane foldery i wykluczenia, postęp i anulowanie na pasku menu, historia z opcją „Przywróć oryginał”,
przenoszenie oryginałów do Kosza, powiadomienia, uruchamianie przy logowaniu. Wszystko działa lokalnie — pliki nigdy nie opuszczają Twojego Maca.

## Budowanie

Wymaga macOS 15+ i narzędzi Command Line Tools (`xcode-select --install`). Xcode jest opcjonalny,
ale projekt można w nim otworzyć jako pakiet Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (uniwersalna: Apple Silicon + Intel); przy pierwszym uruchomieniu buduje FFmpeg (~15 min)
./build.sh install    # instalacja w ~/Applications i uruchomienie
./build.sh dist       # build/RenameConvert.zip (dla automatycznych uaktualnień) i build/RenameConvert.dmg
./build.sh release    # dist + publikacja wydania v<wersja> na GitHub
```

Tłumaczenia: `scripts/extract-strings.py` zbiera teksty interfejsu do `Resources/Localization/keys.json`;
`--check` sprawdza, czy każdy język zawiera wszystkie teksty ze zgodnymi symbolami zastępczymi.
Filmy promocyjne: `scripts/promo/make-promo.sh` (lektor za pomocą `say`, klatki SwiftUI, multipleksowanie przez FFmpeg).

## Architektura

| Plik | Przeznaczenie |
|---|---|
| `RenameWatcher.swift` | FSEvents: wychwytuje pary „stara nazwa → nowa nazwa” |
| `Formats.swift` | Rejestr formatów: który silnik obsługuje daną parę rozszerzeń |
| `Rules.swift` | Reguły i parametry konwersji |
| `Pipeline.swift` | Folder roboczy, uruchomienie silnika, oryginał do Kosza, atomowa zamiana |
| `Engines/ImageEngine.swift` | Obrazy (ImageIO), PDF → obraz |
| `Engines/MediaEngine.swift` | Wideo, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Dokumenty (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archiwa (bsdtar), wspólne błędy |
| `Engines/FFmpegEngine.swift` | Wbudowany FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIF-y z paletą |
| `Updater.swift` | Sprawdzanie i instalowanie uaktualnień z GitHub Releases |
| `BugReport.swift`, `Log.swift` | Zgłaszanie błędów e-mailem, dziennik aplikacji |
| `AppModel.swift` | Ustawienia, kolejka, zapytania, historia, powiadomienia |
| `AskPanel.swift`, `ParamsForm.swift` | Panel potwierdzenia i formularz parametrów |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu na pasku menu i okno ustawień |

## Licencja dołączonych komponentów

FFmpeg jest dołączony jako osobny plik wykonywalny (`Contents/Helpers/ffmpeg`) na licencji LGPL 2.1, zbudowany z LAME (LGPL)
i libwebp (BSD). Ich teksty licencji znajdują się w `Contents/Resources/Licenses`; dokładny skrypt budowania to
`scripts/build-ffmpeg.sh`.
