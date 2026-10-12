<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · **עברית** · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

<div dir="rtl">

# RenameConvert

אפליקציה לשורת התפריטים של macOS: משנים את סיומת הקובץ ב-Finder – וגם הפורמט שלו משתנה.
`photo.heic` ← `photo.jpg`, `clip.mov` ← `clip.mp4`, `clip.mov` ← `clip.gif`, `report.docx` ← `report.pdf`.

![סמל](../Resources/AppIcon.png)

## התקנה

הורידו את **RenameConvert.dmg** מ[הגרסה האחרונה](https://github.com/Kohinor46/RenameConvert/releases/latest)
וגררו את האפליקציה לתיקיית היישומים. נדרש macOS 15 ומעלה, Apple Silicon או Intel.

האפליקציה לא עברה notarization של Apple, ולכן macOS חוסם את ההפעלה הראשונה: לחיצה ימנית על האפליקציה ← **פתח**
(או **פתח בכל זאת** בהגדרות המערכת ← פרטיות ואבטחה).

## תמיכה בפרויקט

RenameConvert הוא חינמי. אם הוא חוסך לכם זמן, אפשר לתמוך בפיתוח:

- **כרטיס בנקאי (בנקים רוסיים):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, ברשת TON בלבד:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ יש לשלוח רק USDT ברשת TON — כספים שיישלחו במטבעות או ברשתות אחרים עלולים ללכת לאיבוד.

אותן אפשרויות, עם קוד QR, זמינות גם באפליקציה: תפריט ← "תמיכה בפרויקט ♥…".

## תכונות

| קטגוריה | מ- | אל |
|---|---|---|
| תמונות | jpg, png, heic, webp, gif, tiff, bmp, RAW ועוד | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| וידאו | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · שמע (m4a, **mp3**, wav, aiff, caf, flac) · פריים (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (מונפש) |
| שמע | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| מסמכים | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF ← תמונה (העמוד הראשון) |
| נתונים | json, plist | json, plist |
| ארכיונים | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | אותם פורמטים |

פורמטים ש-macOS לא יודע לטפל בהם בעצמו (WebP, MP3, MKV, AVI, WebM, OGG…) מומרים באמצעות
**FFmpeg 7.1** המובנה (LGPL 2.1, עם LAME ו-libwebp). הוא נבנה ממקורות רשמיים על ידי `scripts/build-ffmpeg.sh`,
עם בדיקות SHA-256, ותלוי רק בספריות מערכת.

**תפריט ההקשר של Finder:** לחצו לחיצה ימנית על קובץ (או כמה) ← **המרה ל־** ← בחרו פורמט.
הקובץ יומר מיד, כאילו שיניתם את הסיומת שלו. הרחבת Finder מופעלת בהפעלה הראשונה;
אפשר לכבות אותה בהגדרות המערכת ← כללי ← פריטי התחברות והרחבות (או מהאפליקציה: הגדרות ← „הגדרות הרחבות Finder…”).

**כללים.** לכל צמד „מ- ← אל” (סיומת, קטגוריה או „כלשהו”) אתם בוחרים מה יקרה:
לשאול קודם, להמיר מיד או לא להמיר – והאם לשמור את המקור.
הכלל הספציפי ביותר גובר; כברירת מחדל, וידאו מוגדר ל„לשאול” וכל השאר ל„להמיר מיד”.

**חלונית האישור** מופיעה בפינה הימנית העליונה: אפשר לשנות בה את הפרמטרים להמרה הספציפית הזו
ולזכור את ההחלטה עבור צמד הסיומות הזה.

**פרמטרים:** איכות JPEG/HEIC/AVIF/WebP; לווידאו – קודק (ללא קידוד מחדש / H.264 / HEVC),
רזולוציה (4K…480p, ללא הגדלה לעולם), קצב פריימים, הסרת נתוני מיקום ומטא-דאטה אישיים;
קצב פריימים ורוחב של GIF; קצב סיביות של AAC/MP3; גודל עמוד PDF.

**עדכונים:** כפתור „בדיקת עדכונים” ובדיקה אוטומטית יומית מול
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). העדכון מורד,
נבדק באמצעות SHA-256 וחתימת קוד, ומותקן עם הפעלה מחדש.

**דיווח על באג:** תפריט ← „דיווח על באג…” (או הכפתור בהתראת השגיאה) יוצר הודעת דוא״ל אל
המפתח עם התיאור שלכם, פרטי המערכת ויומן האפליקציה כקובץ מצורף. יומן:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 שפות:** אנגלית, רוסית, גרמנית, צרפתית, ספרדית, איטלקית, פורטוגזית (ברזיל), הולנדית, פולנית,
אוקראינית, צ׳כית, שוודית, טורקית, ערבית, עברית, הינדי, אינדונזית, וייטנאמית, תאית, יפנית, קוריאנית,
סינית (מפושטת ומסורתית).

**ובנוסף:** תיקיות במעקב והחרגות, התקדמות וביטול בשורת התפריטים, היסטוריה עם „שחזור המקור”,
העברת המקוריים לפח האשפה, התראות, פתיחה בעת ההתחברות. הכול רץ מקומית – הקבצים אף פעם לא יוצאים מה-Mac שלכם.

## בנייה

נדרשים macOS 15+ ו-Command Line Tools (`xcode-select --install`). Xcode אינו הכרחי,
אבל הפרויקט נפתח בו כחבילת Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (אוניברסלי: Apple Silicon + Intel); בונה את FFmpeg בהרצה הראשונה (~15 דק׳)
./build.sh install    # התקנה ל-~/Applications והפעלה
./build.sh dist       # build/RenameConvert.zip (לעדכון אוטומטי) ו-build/RenameConvert.dmg
./build.sh release    # dist + פרסום הגרסה v<version> ב-GitHub
```

תרגומים: `scripts/extract-strings.py` אוסף את מחרוזות הממשק אל `Resources/Localization/keys.json`;
`--check` מוודא שלכל שפה יש את כל המחרוזות עם מצייני מיקום תואמים.
סרטוני פרומו: `scripts/promo/make-promo.sh` (קריינות באמצעות `say`, פריימים ב-SwiftUI, מיזוג באמצעות FFmpeg).

## ארכיטקטורה

| קובץ | ייעוד |
|---|---|
| `RenameWatcher.swift` | FSEvents: לוכד צמדים של „שם ישן ← שם חדש” |
| `Formats.swift` | רישום הפורמטים: איזה מנוע מטפל בצמד סיומות |
| `Rules.swift` | כללים ופרמטרים של ההמרה |
| `Pipeline.swift` | תיקיית עבודה, הפעלת המנוע, העברת המקור לפח, החלפה אטומית |
| `Engines/ImageEngine.swift` | תמונות (ImageIO), PDF ← תמונה |
| `Engines/MediaEngine.swift` | וידאו, GIF, שמע (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | מסמכים (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, ארכיונים (bsdtar), שגיאות משותפות |
| `Engines/FFmpegEngine.swift` | FFmpeg מובנה: WebP, MP3, MKV, AVI, WebM, OGG, קובצי GIF עם פלטה |
| `Updater.swift` | בדיקה והתקנה של עדכונים מ-GitHub Releases |
| `BugReport.swift`, `Log.swift` | דיווח על באג בדוא״ל, יומן האפליקציה |
| `AppModel.swift` | הגדרות, תור, בקשות אישור, היסטוריה, התראות |
| `AskPanel.swift`, `ParamsForm.swift` | חלונית האישור וטופס הפרמטרים |
| `RenameConvertApp.swift`, `SettingsView.swift` | התפריט בשורת התפריטים וחלון ההגדרות |
| `FinderExtension/`, `FinderMenu.swift` | הרחבת Finder (תת־התפריט „המרה ל־”) וטיפול בבקשות שלה באפליקציה |

## רישיון של רכיבים מצורפים

FFmpeg כלול כקובץ הפעלה נפרד (`Contents/Helpers/ffmpeg`) תחת LGPL 2.1, ונבנה עם LAME (LGPL)
ו-libwebp (BSD). טקסטי הרישיון שלהם נמצאים ב-`Contents/Resources/Licenses`; סקריפט הבנייה המדויק הוא
`scripts/build-ffmpeg.sh`.

</div>
