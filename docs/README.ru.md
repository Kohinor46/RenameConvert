<!-- languages -->
🌐 [English](../README.md) · **Русский** · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Приложение для macOS в строке меню: меняете расширение файла в Finder — меняется его формат.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Иконка](../Resources/AppIcon.png)

## Установка

Скачайте **RenameConvert.dmg** из [последнего релиза](https://github.com/Kohinor46/RenameConvert/releases/latest)
и перетащите приложение в «Программы». Нужна macOS 15 или новее, Apple Silicon или Intel.

Приложение не нотаризовано, поэтому при первом запуске macOS его заблокирует: правый клик по приложению → **Открыть**
(или **Всё равно открыть** в Системных настройках → Конфиденциальность и безопасность).

## Что умеет

| Категория | Из | В |
|---|---|---|
| Картинки | jpg, png, heic, webp, gif, tiff, bmp, RAW и др. | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Видео | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · звук (m4a, **mp3**, wav, aiff, caf, flac) · кадр (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (анимированный) |
| Аудио | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Документы | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → картинка (1-я страница) |
| Данные | json, plist | json, plist |
| Архивы | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | те же |

Форматы, которых нет в macOS (WebP, MP3, MKV, AVI, WebM, OGG…), конвертирует встроенный **FFmpeg 7.1**
(LGPL 2.1, с LAME и libwebp). Он собирается из официальных исходников скриптом `scripts/build-ffmpeg.sh`
со сверкой SHA-256 и зависит только от системных библиотек.

**Правила.** Для каждой пары «из → в» (расширение, категория или «любой») можно выбрать:
спросить, конвертировать сразу или не конвертировать, а также сохранять ли оригинал.
Срабатывает самое конкретное правило; по умолчанию видео — «Спросить», остальное — «Конвертировать сразу».

**Окно-вопрос** появляется в правом верхнем углу: можно поменять параметры именно для этой конвертации
и запомнить решение для пары расширений.

**Параметры:** качество JPEG/HEIC/AVIF/WebP; для видео — кодек (без перекодирования / H.264 / HEVC),
разрешение (4K…480p, без увеличения), частота кадров, удаление геопозиции и личных метаданных;
частота и ширина GIF; битрейт AAC/MP3; размер страницы PDF.

**Обновления:** кнопка «Проверить обновления» и автоматическая проверка раз в сутки по
[релизам на GitHub](https://github.com/Kohinor46/RenameConvert/releases). Обновление скачивается,
проверяется по SHA-256 и подписи и устанавливается с перезапуском.

**Отчёт об ошибке:** меню → «Сообщить об ошибке…» (или кнопка в уведомлении об ошибке) создаёт письмо
разработчику с описанием, сведениями о системе и журналом работы во вложении. Журнал:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 языка:** русский, английский, немецкий, французский, испанский, итальянский, португальский (Бразилия),
нидерландский, польский, украинский, чешский, шведский, турецкий, арабский, иврит, хинди, индонезийский,
вьетнамский, тайский, японский, корейский, китайский (упрощённый и традиционный).

**Ещё:** папки для слежения и исключения, прогресс и отмена в строке меню, история с кнопкой
«Вернуть оригинал», оригинал в Корзину, уведомления, автозапуск. Всё локально — файлы никуда не уходят.

## Сборка

Нужны macOS 15+ и Command Line Tools (`xcode-select --install`). Xcode не обязателен,
но проект открывается в нём как Swift Package (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (универсальный: Apple Silicon + Intel); при первом запуске соберёт FFmpeg (~15 мин)
./build.sh install    # установить в ~/Applications и запустить
./build.sh dist       # build/RenameConvert.zip (для автообновления) и build/RenameConvert.dmg
./build.sh release    # dist + релиз v<версия> на GitHub
```

Переводы: `scripts/extract-strings.py` собирает строки интерфейса в `Resources/Localization/keys.json`,
`--check` проверяет, что во всех языках есть все строки и совпадают подстановки.
Промо-ролики: `scripts/promo/make-promo.sh` (озвучка `say`, кадры SwiftUI, сведение FFmpeg).

## Устройство

| Файл | Что делает |
|---|---|
| `RenameWatcher.swift` | FSEvents: ловит пары «старое имя → новое имя» |
| `Formats.swift` | Реестр форматов: какой движок для пары расширений |
| `Rules.swift` | Правила и параметры конвертации |
| `Pipeline.swift` | Рабочая папка, запуск движка, оригинал в Корзину, атомарная замена |
| `Engines/ImageEngine.swift` | Картинки (ImageIO), PDF → картинка |
| `Engines/MediaEngine.swift` | Видео, GIF, аудио (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Документы (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, архивы (bsdtar), общие ошибки |
| `Engines/FFmpegEngine.swift` | Встроенный FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIF с палитрой |
| `Updater.swift` | Проверка и установка обновлений из GitHub Releases |
| `BugReport.swift`, `Log.swift` | Отчёт об ошибке письмом, журнал работы |
| `AppModel.swift` | Настройки, очередь, вопросы, история, уведомления |
| `AskPanel.swift`, `ParamsForm.swift` | Окно-вопрос и форма параметров |
| `RenameConvertApp.swift`, `SettingsView.swift` | Меню в строке меню и окно настроек |

## Лицензии встроенных компонентов

FFmpeg входит в приложение отдельным исполняемым файлом (`Contents/Helpers/ffmpeg`) под LGPL 2.1, собран с LAME (LGPL)
и libwebp (BSD). Тексты лицензий — в `Contents/Resources/Licenses`, точный скрипт сборки — `scripts/build-ffmpeg.sh`.
