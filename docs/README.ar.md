<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · **العربية** · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

<div dir="rtl">

# RenameConvert

تطبيق لشريط القوائم في macOS: غيّر امتداد الملف في Finder وسيتغير تنسيقه أيضًا.
`photo.heic` ← `photo.jpg`، و`clip.mov` ← `clip.mp4`، و`clip.mov` ← `clip.gif`، و`report.docx` ← `report.pdf`.

![الأيقونة](../Resources/AppIcon.png)

## التثبيت

نزّل **RenameConvert.dmg** من [أحدث إصدار](https://github.com/Kohinor46/RenameConvert/releases/latest)
واسحب التطبيق إلى مجلد التطبيقات. يتطلب macOS 15 أو أحدث، على Apple Silicon أو Intel.

التطبيق غير موثَّق (notarized) من Apple، لذا يمنع macOS تشغيله في المرة الأولى: انقر بزر الماوس الأيمن على التطبيق ← **فتح**
(أو **الفتح على أي حال** في إعدادات النظام ← الخصوصية والأمن).

## ادعم المشروع

RenameConvert مجاني. إذا كان يوفّر وقتك، يمكنك دعم تطويره:

- **بطاقة مصرفية (البنوك الروسية):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT، على شبكة TON فقط:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ أرسل USDT على شبكة TON فقط — قد تضيع الأموال المرسلة بعملات أو عبر شبكات أخرى.

الخيارات نفسها، مع رمز QR، متوفرة في التطبيق: القائمة ← "ادعم المشروع ♥…".

## الميزات

| الفئة | من | إلى |
|---|---|---|
| الصور | jpg وpng وheic وwebp وgif وtiff وbmp وRAW وغيرها | jpg، png، heic، avif، **webp**، gif، tiff، bmp، jp2، ico، icns، psd، tga، pdf |
| الفيديو | mov، mp4، m4v، 3gp، **mkv، avi، webm، flv، wmv، mpg، ts، mts، ogv** | mov، mp4، m4v، **mkv** · **gif** · صوت (m4a، **mp3**، wav، aiff، caf، flac) · إطار (jpg، png…) |
| GIF | gif | mp4، mov، m4v، webp (متحرك) |
| الصوت | mp3، m4a، aac، wav، aiff، caf، flac، **ogg، opus، wma، ac3، amr، ape** | m4a، **mp3**، wav، aiff، caf، flac |
| المستندات | txt، rtf، html، docx، doc، odt، webarchive، pdf | txt، rtf، html، docx، doc، odt، pdf · PDF ← صورة (الصفحة الأولى) |
| البيانات | json، plist | json، plist |
| الأرشيفات | zip، tar، tar.gz، tar.bz2، tar.xz، 7z | التنسيقات نفسها |

التنسيقات التي لا يستطيع macOS التعامل معها بمفرده (WebP وMP3 وMKV وAVI وWebM وOGG…) يحوّلها
**FFmpeg 7.1** المدمج (LGPL 2.1، مع LAME وlibwebp). يُبنى من المصادر الرسمية بواسطة `scripts/build-ffmpeg.sh`
مع التحقق من SHA-256، ولا يعتمد إلا على مكتبات النظام.

**قائمة السياق في Finder:** انقر بزر الماوس الأيمن على ملف (أو عدة ملفات) ← **تحويل إلى** ← اختر صيغة.
يُحوَّل الملف فورًا كأنك غيّرت امتداده. يُفعَّل امتداد Finder عند التشغيل الأول؛
ويمكنك إيقافه من إعدادات النظام ← عام ← عناصر تسجيل الدخول والامتدادات (أو من التطبيق: الإعدادات ← «إعدادات امتدادات Finder…»).

**القواعد.** لكل زوج «من ← إلى» (امتداد أو فئة أو «أي») تختار ما يحدث:
السؤال أولًا، أو التحويل فورًا، أو عدم التحويل — وما إذا كان سيُحتفظ بالملف الأصلي.
تُطبَّق القاعدة الأكثر تحديدًا؛ افتراضيًا يكون الفيديو على «السؤال» وكل ما عداه على «التحويل فورًا».

**لوحة التأكيد** تظهر في الزاوية العلوية اليمنى: يمكنك فيها تغيير المعلمات لهذا التحويل تحديدًا
وتذكّر القرار لهذا الزوج من الامتدادات.

**المعلمات:** جودة JPEG/HEIC/AVIF/WebP؛ وللفيديو — برنامج الترميز (بدون إعادة ترميز / H.264 / HEVC)،
والدقة (4K…480p، دون تكبير أبدًا)، ومعدل الإطارات، وإزالة بيانات الموقع والبيانات الوصفية الشخصية؛
ومعدل إطارات GIF وعرضه؛ ومعدل بت AAC/MP3؛ وحجم صفحة PDF.

**التحديثات:** زر «التحقق من وجود تحديثات» وفحص تلقائي يومي عبر
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). يُنزَّل التحديث،
ويُتحقق منه عبر SHA-256 وتوقيع الشيفرة، ثم يُثبَّت مع إعادة تشغيل التطبيق.

**الإبلاغ عن الأخطاء:** القائمة ← «الإبلاغ عن خطأ…» (أو الزر في إشعار الخطأ) ينشئ رسالة بريد إلكتروني إلى
المطوّر تتضمن وصفك ومعلومات النظام مع إرفاق سجل التطبيق. السجل:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 لغة:** الإنجليزية، الروسية، الألمانية، الفرنسية، الإسبانية، الإيطالية، البرتغالية (البرازيل)، الهولندية، البولندية،
الأوكرانية، التشيكية، السويدية، التركية، العربية، العبرية، الهندية، الإندونيسية، الفيتنامية، التايلاندية، اليابانية، الكورية،
الصينية (المبسطة والتقليدية).

**وأيضًا:** مجلدات مراقَبة واستثناءات، وعرض التقدم والإلغاء في شريط القوائم، وسجل مع «استعادة الأصل»،
ونقل الملفات الأصلية إلى سلة المهملات، والإشعارات، والفتح عند تسجيل الدخول. كل شيء يعمل محليًا — لا تغادر ملفاتك جهاز Mac أبدًا.

## البناء

يتطلب macOS 15+ وأدوات سطر الأوامر (`xcode-select --install`). Xcode اختياري،
لكن المشروع يُفتح فيه كحزمة Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (عام: Apple Silicon + Intel)؛ يبني FFmpeg عند التشغيل الأول (~15 دقيقة)
./build.sh install    # التثبيت في ~/Applications والتشغيل
./build.sh dist       # build/RenameConvert.zip (للتحديث التلقائي) و build/RenameConvert.dmg
./build.sh release    # dist + نشر الإصدار v<version> على GitHub
```

الترجمات: يجمع `scripts/extract-strings.py` نصوص الواجهة في `Resources/Localization/keys.json`؛
ويتحقق `--check` من أن كل لغة تحتوي على كل النصوص مع عناصر نائبة مطابقة.
الفيديوهات الترويجية: `scripts/promo/make-promo.sh` (تعليق صوتي عبر `say`، وإطارات SwiftUI، ودمج باستخدام FFmpeg).

## البنية

| الملف | الغرض |
|---|---|
| `RenameWatcher.swift` | FSEvents: يلتقط أزواج «الاسم القديم ← الاسم الجديد» |
| `Formats.swift` | سجل التنسيقات: أي محرك يعالج زوج الامتدادات |
| `Rules.swift` | القواعد ومعلمات التحويل |
| `Pipeline.swift` | مجلد العمل، وتشغيل المحرك، ونقل الأصل إلى سلة المهملات، والاستبدال الذري |
| `Engines/ImageEngine.swift` | الصور (ImageIO)، وPDF ← صورة |
| `Engines/MediaEngine.swift` | الفيديو وGIF والصوت (AVFoundation وafconvert) |
| `Engines/DocumentEngine.swift` | المستندات (NSAttributedString وPDFKit وCoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist، والأرشيفات (bsdtar)، والأخطاء المشتركة |
| `Engines/FFmpegEngine.swift` | FFmpeg المدمج: WebP وMP3 وMKV وAVI وWebM وOGG وصور GIF بلوحة ألوان |
| `Updater.swift` | التحقق من التحديثات وتثبيتها من GitHub Releases |
| `BugReport.swift`، `Log.swift` | الإبلاغ عن الأخطاء عبر البريد الإلكتروني، وسجل التطبيق |
| `AppModel.swift` | الإعدادات وقائمة الانتظار والمطالبات والسجل والإشعارات |
| `AskPanel.swift`، `ParamsForm.swift` | لوحة التأكيد ونموذج المعلمات |
| `RenameConvertApp.swift`، `SettingsView.swift` | قائمة شريط القوائم ونافذة الإعدادات |
| `FinderExtension/`, `FinderMenu.swift` | امتداد Finder (القائمة الفرعية «تحويل إلى») ومعالجة طلباته في التطبيق |

## ترخيص المكونات المضمّنة

يُضمَّن FFmpeg كملف تنفيذي منفصل (`Contents/Helpers/ffmpeg`) بموجب LGPL 2.1، وهو مبني مع LAME (LGPL)
وlibwebp (BSD). نصوص تراخيصها موجودة في `Contents/Resources/Licenses`؛ وسكربت البناء الدقيق هو
`scripts/build-ffmpeg.sh`.

</div>
