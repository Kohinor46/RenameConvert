<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · **ไทย** · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

แอปบนแถบเมนูของ macOS: เปลี่ยนนามสกุลไฟล์ใน Finder แล้วรูปแบบไฟล์ก็จะเปลี่ยนตามไปด้วย
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`

![ไอคอน](../Resources/AppIcon.png)

## การติดตั้ง

ดาวน์โหลด **RenameConvert.dmg** จาก[รุ่นล่าสุด](https://github.com/Kohinor46/RenameConvert/releases/latest)
แล้วลากแอปไปไว้ในโฟลเดอร์แอปพลิเคชัน ต้องใช้ macOS 15 ขึ้นไป บน Apple Silicon หรือ Intel

แอปนี้ไม่ได้ผ่านการรับรอง (notarize) ดังนั้น macOS จะบล็อกการเปิดครั้งแรก: คลิกขวาที่แอป → **เปิด**
(หรือ **เปิดต่อไป** ในการตั้งค่าระบบ → ความเป็นส่วนตัวและความปลอดภัย)

## สนับสนุนโปรเจกต์

RenameConvert ใช้งานได้ฟรี หากช่วยประหยัดเวลาของคุณ คุณสามารถสนับสนุนการพัฒนาได้:

- **บัตรธนาคาร (ธนาคารรัสเซีย):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT เฉพาะเครือข่าย TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ ส่งเฉพาะ USDT บนเครือข่าย TON เท่านั้น — เหรียญหรือเครือข่ายอื่นอาจสูญหาย

ตัวเลือกเดียวกันพร้อมคิวอาร์โค้ดมีอยู่ในแอปด้วย: เมนู → "สนับสนุนโปรเจกต์ ♥…"

## คุณสมบัติ

| หมวดหมู่ | จาก | เป็น |
|---|---|---|
| รูปภาพ | jpg, png, heic, webp, gif, tiff, bmp, RAW และอื่นๆ | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| วิดีโอ | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · เสียง (m4a, **mp3**, wav, aiff, caf, flac) · เฟรม (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (ภาพเคลื่อนไหว) |
| เสียง | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| เอกสาร | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → รูปภาพ (หน้าแรก) |
| ข้อมูล | json, plist | json, plist |
| ไฟล์เก็บถาวร | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | รูปแบบเดียวกัน |

รูปแบบที่ macOS จัดการเองไม่ได้ (WebP, MP3, MKV, AVI, WebM, OGG…) จะถูกแปลงด้วย
**FFmpeg 7.1** ที่มาพร้อมแอป (LGPL 2.1 พร้อม LAME และ libwebp) ซึ่งสร้างจากซอร์สโค้ดทางการด้วย `scripts/build-ffmpeg.sh`
มีการตรวจสอบ SHA-256 และพึ่งพาเฉพาะไลบรารีของระบบเท่านั้น

**เมนูคลิกขวาใน Finder:** คลิกขวาที่ไฟล์ (หรือหลายไฟล์) → **แปลงเป็น** → เลือกรูปแบบ
ไฟล์จะถูกแปลงทันที เหมือนคุณเปลี่ยนนามสกุลไฟล์เอง ส่วนขยาย Finder จะเปิดเมื่อเปิดแอปครั้งแรก
ปิดได้ที่การตั้งค่าระบบ → ทั่วไป → รายการเข้าสู่ระบบและส่วนขยาย (หรือในแอป: การตั้งค่า → “ตั้งค่าส่วนขยาย Finder…”)

**กฎ** สำหรับคู่ "จาก → เป็น" ใดๆ (นามสกุลไฟล์ หมวดหมู่ หรือ "ใดก็ได้") คุณเลือกได้ว่าจะให้เกิดอะไรขึ้น:
ถามก่อน แปลงทันที หรือไม่แปลง — และจะเก็บต้นฉบับไว้หรือไม่
กฎที่เจาะจงที่สุดจะมีผลเหนือกว่า ค่าเริ่มต้นคือวิดีโอเป็น "ถาม" และอย่างอื่นทั้งหมดเป็น "แปลงทันที"

**แผงยืนยัน** จะปรากฏที่มุมขวาบน: เปลี่ยนพารามิเตอร์สำหรับการแปลงครั้งนี้โดยเฉพาะ
และจดจำการตัดสินใจสำหรับคู่นามสกุลไฟล์นี้

**พารามิเตอร์:** คุณภาพ JPEG/HEIC/AVIF/WebP; สำหรับวิดีโอ — ตัวแปลงสัญญาณ (ไม่เข้ารหัสใหม่ / H.264 / HEVC),
ความละเอียด (4K…480p ไม่ขยายขนาดขึ้น), อัตราเฟรม, การลบตำแหน่งที่ตั้งและข้อมูลเมตาส่วนบุคคล;
อัตราเฟรมและความกว้างของ GIF; บิตเรต AAC/MP3; ขนาดหน้า PDF

**การอัปเดต:** ปุ่ม "ตรวจสอบหารายการอัปเดต" และการตรวจสอบอัตโนมัติทุกวันกับ
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases) อัปเดตจะถูกดาวน์โหลด
ตรวจสอบด้วย SHA-256 และลายเซ็นโค้ด แล้วติดตั้งพร้อมเปิดแอปใหม่

**รายงานข้อผิดพลาด:** เมนู → "รายงานข้อผิดพลาด…" (หรือปุ่มในการแจ้งเตือนข้อผิดพลาด) จะสร้างอีเมลถึง
นักพัฒนาพร้อมคำอธิบายของคุณ ข้อมูลระบบ และแนบบันทึกของแอป บันทึก:
`~/Library/Logs/RenameConvert/RenameConvert.log`

**23 ภาษา:** อังกฤษ, รัสเซีย, เยอรมัน, ฝรั่งเศส, สเปน, อิตาลี, โปรตุเกส (บราซิล), ดัตช์, โปแลนด์,
ยูเครน, เช็ก, สวีเดน, ตุรกี, อาหรับ, ฮีบรู, ฮินดี, อินโดนีเซีย, เวียดนาม, ไทย, ญี่ปุ่น, เกาหลี,
จีน (ตัวย่อและตัวเต็ม)

**นอกจากนี้:** โฟลเดอร์ที่เฝ้าดูและรายการยกเว้น, ความคืบหน้าและการยกเลิกบนแถบเมนู, ประวัติพร้อม "กู้คืนต้นฉบับ",
ย้ายต้นฉบับไปที่ถังขยะ, การแจ้งเตือน, เปิดเมื่อเข้าสู่ระบบ ทุกอย่างทำงานภายในเครื่อง — ไฟล์จะไม่ออกจาก Mac ของคุณ

## การสร้าง

ต้องใช้ macOS 15+ และ Command Line Tools (`xcode-select --install`) ส่วน Xcode ไม่จำเป็น
แต่สามารถเปิดโปรเจกต์ใน Xcode ในรูปแบบแพ็กเกจ Swift ได้ (`open Package.swift`)

```bash
./build.sh            # build/RenameConvert.app (ยูนิเวอร์แซล: Apple Silicon + Intel); สร้าง FFmpeg ในการรันครั้งแรก (~15 นาที)
./build.sh install    # ติดตั้งไปที่ ~/Applications แล้วเปิดแอป
./build.sh dist       # build/RenameConvert.zip (สำหรับการอัปเดตอัตโนมัติ) และ build/RenameConvert.dmg
./build.sh release    # dist + เผยแพร่รุ่น v<version> บน GitHub
```

การแปล: `scripts/extract-strings.py` รวบรวมข้อความของ UI ไว้ใน `Resources/Localization/keys.json`;
`--check` ตรวจสอบว่าทุกภาษามีข้อความครบทุกรายการและตัวยึดตำแหน่งตรงกัน
วิดีโอโปรโมต: `scripts/promo/make-promo.sh` (บรรยายเสียงด้วย `say`, เฟรมจาก SwiftUI, รวมด้วย FFmpeg)

## สถาปัตยกรรม

| ไฟล์ | หน้าที่ |
|---|---|
| `RenameWatcher.swift` | FSEvents: ตรวจจับคู่ "ชื่อเดิม → ชื่อใหม่" |
| `Formats.swift` | ทะเบียนรูปแบบ: เอนจินใดจัดการคู่นามสกุลไฟล์ใด |
| `Rules.swift` | กฎและพารามิเตอร์การแปลง |
| `Pipeline.swift` | โฟลเดอร์ทำงาน, การรันเอนจิน, ย้ายต้นฉบับไปถังขยะ, การแทนที่แบบอะตอมิก |
| `Engines/ImageEngine.swift` | รูปภาพ (ImageIO), PDF → รูปภาพ |
| `Engines/MediaEngine.swift` | วิดีโอ, GIF, เสียง (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | เอกสาร (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, ไฟล์เก็บถาวร (bsdtar), ข้อผิดพลาดที่ใช้ร่วมกัน |
| `Engines/FFmpegEngine.swift` | FFmpeg ในตัว: WebP, MP3, MKV, AVI, WebM, OGG, GIF แบบพาเลต |
| `Updater.swift` | ตรวจสอบและติดตั้งอัปเดตจาก GitHub Releases |
| `BugReport.swift`, `Log.swift` | รายงานข้อผิดพลาดทางอีเมล, บันทึกของแอป |
| `AppModel.swift` | การตั้งค่า, คิว, การถามยืนยัน, ประวัติ, การแจ้งเตือน |
| `AskPanel.swift`, `ParamsForm.swift` | แผงยืนยันและฟอร์มพารามิเตอร์ |
| `RenameConvertApp.swift`, `SettingsView.swift` | เมนูบนแถบเมนูและหน้าต่างการตั้งค่า |
| `FinderExtension/`, `FinderMenu.swift` | ส่วนขยาย Finder (เมนูย่อย “แปลงเป็น”) และการจัดการคำขอของมันในแอป |

## สัญญาอนุญาตของคอมโพเนนต์ที่มาพร้อมแอป

FFmpeg รวมมาเป็นไฟล์ปฏิบัติการแยกต่างหาก (`Contents/Helpers/ffmpeg`) ภายใต้ LGPL 2.1 โดยสร้างร่วมกับ LAME (LGPL)
และ libwebp (BSD) ข้อความสัญญาอนุญาตอยู่ใน `Contents/Resources/Licenses` และสคริปต์สร้างที่ใช้จริงคือ
`scripts/build-ffmpeg.sh`
