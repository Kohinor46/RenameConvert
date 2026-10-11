<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · **हिन्दी** · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

macOS मेनू बार ऐप: Finder में फ़ाइल का एक्सटेंशन बदलें, और उसका फ़ॉर्मैट भी बदल जाएगा।
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`।

![आइकन](../Resources/AppIcon.png)

## इंस्टॉल करना

[नवीनतम रिलीज़](https://github.com/Kohinor46/RenameConvert/releases/latest) से **RenameConvert.dmg** डाउनलोड करें
और ऐप को ऐप्लिकेशन फ़ोल्डर में ड्रैग करें। macOS 15 या बाद का संस्करण आवश्यक है, Apple Silicon या Intel।

ऐप नोटराइज़्ड नहीं है, इसलिए macOS पहली बार खोलने पर उसे ब्लॉक कर देता है: ऐप पर राइट-क्लिक करें → **खोलें**
(या सिस्टम सेटिंग्ज़ → गोपनीयता और सुरक्षा में **फिर भी खोलें**)।

## विशेषताएँ

| श्रेणी | से | में |
|---|---|---|
| इमेज | jpg, png, heic, webp, gif, tiff, bmp, RAW और अन्य | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| वीडियो | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · ऑडियो (m4a, **mp3**, wav, aiff, caf, flac) · फ़्रेम (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (एनिमेटेड) |
| ऑडियो | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| दस्तावेज़ | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → इमेज (पहला पेज) |
| डेटा | json, plist | json, plist |
| आर्काइव | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | यही फ़ॉर्मैट |

जिन फ़ॉर्मैट को macOS अपने आप संभाल नहीं सकता (WebP, MP3, MKV, AVI, WebM, OGG…), उन्हें बिल्ट-इन
**FFmpeg 7.1** (LGPL 2.1, LAME और libwebp के साथ) कन्वर्ट करता है। इसे `scripts/build-ffmpeg.sh` आधिकारिक सोर्स से
SHA-256 जाँच के साथ बनाता है, और यह केवल सिस्टम लाइब्रेरी पर निर्भर है।

**नियम।** हर "से → में" जोड़ी (एक्सटेंशन, श्रेणी या "कोई भी") के लिए आप चुनते हैं कि क्या होगा:
पहले पूछें, तुरंत कन्वर्ट करें या कन्वर्ट न करें — और यह भी कि मूल फ़ाइल रखनी है या नहीं।
सबसे विशिष्ट नियम लागू होता है; डिफ़ॉल्ट रूप से वीडियो के लिए "पूछें" और बाकी सब के लिए "तुरंत कन्वर्ट करें" होता है।

**पुष्टि पैनल** ऊपरी दाएँ कोने में दिखाई देता है: इसमें आप इस खास कन्वर्ज़न के पैरामीटर बदल सकते हैं
और एक्सटेंशन की इस जोड़ी के लिए अपना निर्णय याद रख सकते हैं।

**पैरामीटर:** JPEG/HEIC/AVIF/WebP की क्वालिटी; वीडियो के लिए — कोडेक (बिना री-एन्कोडिंग / H.264 / HEVC),
रिज़ॉल्यूशन (4K…480p, कभी अपस्केल नहीं), फ़्रेम रेट, लोकेशन और निजी मेटाडेटा हटाना;
GIF का फ़्रेम रेट और चौड़ाई; AAC/MP3 का बिटरेट; PDF पेज का आकार।

**अपडेट:** "अपडेट जाँचें" बटन और
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases) से रोज़ाना स्वचालित जाँच। अपडेट डाउनलोड होता है,
SHA-256 और कोड सिग्नेचर से सत्यापित होता है, और ऐप को फिर से शुरू करके इंस्टॉल होता है।

**बग रिपोर्ट:** मेनू → "बग रिपोर्ट करें…" (या त्रुटि सूचना में बटन) डेवलपर के लिए एक ईमेल बनाता है,
जिसमें आपका विवरण, सिस्टम जानकारी और संलग्न ऐप लॉग होता है। लॉग:
`~/Library/Logs/RenameConvert/RenameConvert.log`।

**23 भाषाएँ:** अंग्रेज़ी, रूसी, जर्मन, फ़्रेंच, स्पैनिश, इतालवी, पुर्तगाली (ब्राज़ील), डच, पोलिश,
यूक्रेनी, चेक, स्वीडिश, तुर्की, अरबी, हिब्रू, हिन्दी, इंडोनेशियाई, वियतनामी, थाई, जापानी, कोरियाई,
चीनी (सरलीकृत और पारंपरिक)।

**इसके अलावा:** निगरानी वाले फ़ोल्डर और अपवाद, मेनू बार में प्रगति और रद्द करने का विकल्प, "मूल वापस लाएँ" के साथ इतिहास,
मूल फ़ाइलें ट्रैश में भेजी जाती हैं, सूचनाएँ, लॉग इन करने पर खोलें। सब कुछ लोकल चलता है — फ़ाइलें कभी आपके Mac से बाहर नहीं जातीं।

## बिल्ड करना

macOS 15+ और Command Line Tools (`xcode-select --install`) आवश्यक हैं। Xcode वैकल्पिक है,
लेकिन प्रोजेक्ट उसमें Swift पैकेज के रूप में खुलता है (`open Package.swift`)।

```bash
./build.sh            # build/RenameConvert.app (यूनिवर्सल: Apple Silicon + Intel); पहली बार चलाने पर FFmpeg बिल्ड करता है (~15 मिनट)
./build.sh install    # ~/Applications में इंस्टॉल करें और चलाएँ
./build.sh dist       # build/RenameConvert.zip (ऑटो-अपडेट के लिए) और build/RenameConvert.dmg
./build.sh release    # dist + GitHub पर रिलीज़ v<version> प्रकाशित करें
```

अनुवाद: `scripts/extract-strings.py` UI स्ट्रिंग्स को `Resources/Localization/keys.json` में इकट्ठा करता है;
`--check` जाँचता है कि हर भाषा में हर स्ट्रिंग मौजूद है और प्लेसहोल्डर मेल खाते हैं।
प्रोमो वीडियो: `scripts/promo/make-promo.sh` (`say` से वॉइस-ओवर, SwiftUI फ़्रेम, FFmpeg से मक्सिंग)।

## आर्किटेक्चर

| फ़ाइल | उद्देश्य |
|---|---|
| `RenameWatcher.swift` | FSEvents: "पुराना नाम → नया नाम" जोड़ियाँ पकड़ता है |
| `Formats.swift` | फ़ॉर्मैट रजिस्ट्री: एक्सटेंशन की जोड़ी को कौन-सा इंजन संभालता है |
| `Rules.swift` | नियम और कन्वर्ज़न पैरामीटर |
| `Pipeline.swift` | वर्क फ़ोल्डर, इंजन चलाना, मूल फ़ाइल ट्रैश में, एटॉमिक रिप्लेस |
| `Engines/ImageEngine.swift` | इमेज (ImageIO), PDF → इमेज |
| `Engines/MediaEngine.swift` | वीडियो, GIF, ऑडियो (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | दस्तावेज़ (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, आर्काइव (bsdtar), साझा त्रुटियाँ |
| `Engines/FFmpegEngine.swift` | बिल्ट-इन FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, पैलेट वाले GIF |
| `Updater.swift` | GitHub Releases से अपडेट जाँचना और इंस्टॉल करना |
| `BugReport.swift`, `Log.swift` | ईमेल से बग रिपोर्ट, ऐप लॉग |
| `AppModel.swift` | सेटिंग्स, कतार, संकेत, इतिहास, सूचनाएँ |
| `AskPanel.swift`, `ParamsForm.swift` | पुष्टि पैनल और पैरामीटर फ़ॉर्म |
| `RenameConvertApp.swift`, `SettingsView.swift` | मेनू बार मेनू और सेटिंग्स विंडो |

## शामिल घटकों का लाइसेंस

FFmpeg एक अलग एक्ज़िक्यूटेबल (`Contents/Helpers/ffmpeg`) के रूप में LGPL 2.1 के तहत शामिल है, और LAME (LGPL)
तथा libwebp (BSD) के साथ बिल्ड किया गया है। उनके लाइसेंस टेक्स्ट `Contents/Resources/Licenses` में हैं; सटीक बिल्ड स्क्रिप्ट
`scripts/build-ffmpeg.sh` है।
