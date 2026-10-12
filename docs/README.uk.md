<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · **Українська** · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Застосунок для смуги меню macOS: змініть розширення файлу у Finder — і зміниться його формат.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Іконка](../Resources/AppIcon.png)

## Встановлення

Завантажте **RenameConvert.dmg** з [останнього релізу](https://github.com/Kohinor46/RenameConvert/releases/latest)
і перетягніть застосунок до папки «Програми». Потрібна macOS 15 або новіша, Apple Silicon чи Intel.

Застосунок не нотаризовано, тому macOS блокує перший запуск: клацніть застосунок правою кнопкою → **Відкрити**
(або **Усе одно відкрити** в Системних параметрах → Приватність і безпека).

## Підтримати проєкт

RenameConvert безкоштовний. Якщо він заощаджує вам час, ви можете підтримати розробку:

- **Банківська картка (російські банки):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, лише мережа TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Надсилайте лише USDT у мережі TON — інші монети чи мережі можуть бути втрачені.

Ті самі способи з QR-кодом є в застосунку: меню → «Підтримати проєкт ♥…».

## Можливості

| Категорія | З | У |
|---|---|---|
| Зображення | jpg, png, heic, webp, gif, tiff, bmp, RAW та інші | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Відео | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · аудіо (m4a, **mp3**, wav, aiff, caf, flac) · кадр (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (анімований) |
| Аудіо | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Документи | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → зображення (перша сторінка) |
| Дані | json, plist | json, plist |
| Архіви | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | ті самі |

Формати, з якими macOS не працює самостійно (WebP, MP3, MKV, AVI, WebM, OGG…), конвертує вбудований
**FFmpeg 7.1** (LGPL 2.1, з LAME і libwebp). Його зібрано з офіційних джерел скриптом `scripts/build-ffmpeg.sh`
з перевіркою SHA-256, і він залежить лише від системних бібліотек.

**Контекстне меню Finder:** клацніть файл (або кілька) правою кнопкою → **Конвертувати в** → виберіть формат.
Файл одразу сконвертується, ніби ви змінили йому розширення. Розширення Finder вмикається під час першого запуску;
вимкнути його можна в Системних параметрах → Загальні → Об’єкти входу та розширення (або в застосунку: Налаштування → «Налаштувати розширення Finder…»).

**Правила.** Для будь-якої пари «з → у» (розширення, категорія або «будь-яке») ви обираєте, що відбувається:
спершу запитати, конвертувати одразу чи не конвертувати — і чи зберігати оригінал.
Перемагає найконкретніше правило; типово для відео встановлено «Запитати», а для всього іншого — «Конвертувати одразу».

**Панель підтвердження** з’являється у правому верхньому куті: змініть параметри саме цієї конвертації
й запам’ятайте рішення для цієї пари розширень.

**Параметри:** якість JPEG/HEIC/AVIF/WebP; для відео — кодек (без перекодування / H.264 / HEVC),
роздільність (4K…480p, без збільшення), частота кадрів, видалення геопозиції та особистих метаданих;
частота кадрів і ширина GIF; бітрейт AAC/MP3; розмір сторінки PDF.

**Оновлення:** кнопка «Перевірити оновлення» та автоматична щоденна перевірка в
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Оновлення завантажується,
перевіряється за SHA-256 і підписом коду та встановлюється з перезапуском.

**Повідомлення про помилку:** меню → «Повідомити про помилку…» (або кнопка в сповіщенні про помилку) створює лист
розробнику з вашим описом, відомостями про систему та доданим журналом застосунку. Журнал:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 мови:** англійська, російська, німецька, французька, іспанська, італійська, португальська (Бразилія), нідерландська, польська,
українська, чеська, шведська, турецька, арабська, іврит, гінді, індонезійська, в’єтнамська, тайська, японська, корейська,
китайська (спрощена й традиційна).

**Також:** відстежувані папки й винятки, прогрес і скасування в смузі меню, історія з функцією «Повернути оригінал»,
переміщення оригіналів у Смітник, сповіщення, запуск під час входу. Усе працює локально — файли ніколи не залишають ваш Mac.

## Збирання

Потрібні macOS 15+ і Command Line Tools (`xcode-select --install`). Xcode не обов’язковий,
але проєкт відкривається в ньому як пакет Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (універсальний: Apple Silicon + Intel); під час першого запуску збирає FFmpeg (~15 хв)
./build.sh install    # встановити в ~/Applications і запустити
./build.sh dist       # build/RenameConvert.zip (для автооновлення) і build/RenameConvert.dmg
./build.sh release    # dist + публікація релізу v<версія> на GitHub
```

Переклади: `scripts/extract-strings.py` збирає рядки інтерфейсу в `Resources/Localization/keys.json`;
`--check` перевіряє, що кожна мова містить усі рядки з відповідними плейсхолдерами.
Промовідео: `scripts/promo/make-promo.sh` (озвучення через `say`, кадри SwiftUI, зведення за допомогою FFmpeg).

## Архітектура

| Файл | Призначення |
|---|---|
| `RenameWatcher.swift` | FSEvents: відловлює пари «стара назва → нова назва» |
| `Formats.swift` | Реєстр форматів: який рушій обробляє пару розширень |
| `Rules.swift` | Правила й параметри конвертації |
| `Pipeline.swift` | Робоча папка, запуск рушія, оригінал у Смітник, атомарна заміна |
| `Engines/ImageEngine.swift` | Зображення (ImageIO), PDF → зображення |
| `Engines/MediaEngine.swift` | Відео, GIF, аудіо (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Документи (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, архіви (bsdtar), спільні помилки |
| `Engines/FFmpegEngine.swift` | Вбудований FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, GIF із палітрою |
| `Updater.swift` | Перевірка та встановлення оновлень із GitHub Releases |
| `BugReport.swift`, `Log.swift` | Повідомлення про помилку електронною поштою, журнал застосунку |
| `AppModel.swift` | Налаштування, черга, запити, історія, сповіщення |
| `AskPanel.swift`, `ParamsForm.swift` | Панель підтвердження та форма параметрів |
| `RenameConvertApp.swift`, `SettingsView.swift` | Меню в смузі меню та вікно налаштувань |
| `FinderExtension/`, `FinderMenu.swift` | Розширення Finder (підменю «Конвертувати в») і обробка його запитів у застосунку |

## Ліцензія вбудованих компонентів

FFmpeg постачається як окремий виконуваний файл (`Contents/Helpers/ffmpeg`) за ліцензією LGPL 2.1, зібраний із LAME (LGPL)
і libwebp (BSD). Тексти їхніх ліцензій містяться в `Contents/Resources/Licenses`; точний скрипт збирання —
`scripts/build-ffmpeg.sh`.
