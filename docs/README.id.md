<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · **Bahasa Indonesia** · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Aplikasi bar menu macOS: ubah ekstensi file di Finder, dan formatnya ikut berubah.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Ikon](../Resources/AppIcon.png)

## Instalasi

Unduh **RenameConvert.dmg** dari [rilis terbaru](https://github.com/Kohinor46/RenameConvert/releases/latest)
lalu seret aplikasi ke folder Aplikasi. Memerlukan macOS 15 atau lebih baru, Apple Silicon atau Intel.

Aplikasi ini belum dinotarisasi, sehingga macOS memblokir peluncuran pertama: klik kanan aplikasi → **Buka**
(atau **Tetap Buka** di Pengaturan Sistem → Privasi & Keamanan).

## Dukung proyek ini

RenameConvert gratis. Jika aplikasi ini menghemat waktu Anda, Anda dapat mendukung pengembangannya:

- **Kartu bank (bank Rusia):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, hanya jaringan TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Kirim hanya USDT di jaringan TON — koin atau jaringan lain bisa hilang.

Opsi yang sama, beserta kode QR, tersedia di aplikasi: menu → "Dukung Proyek ♥…".

## Fitur

| Kategori | Dari | Ke |
|---|---|---|
| Gambar | jpg, png, heic, webp, gif, tiff, bmp, RAW, dan lainnya | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · bingkai (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animasi) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Dokumen | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → gambar (halaman pertama) |
| Data | json, plist | json, plist |
| Arsip | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | format yang sama |

Format yang tidak dapat ditangani macOS sendiri (WebP, MP3, MKV, AVI, WebM, OGG…) dikonversi oleh
**FFmpeg 7.1** bawaan (LGPL 2.1, dengan LAME dan libwebp). FFmpeg dibangun dari sumber resmi oleh `scripts/build-ffmpeg.sh`,
dengan pemeriksaan SHA-256, dan hanya bergantung pada pustaka sistem.

**Aturan.** Untuk setiap pasangan "dari → ke" (ekstensi, kategori, atau "Apa saja") Anda memilih apa yang terjadi:
tanyakan dulu, langsung konversi, atau jangan konversi — serta apakah file asli disimpan.
Aturan yang paling spesifik yang berlaku; secara default video diatur ke "Tanyakan" dan lainnya ke "Langsung konversi".

**Panel konfirmasi** muncul di sudut kanan atas: ubah parameter untuk konversi ini secara khusus
dan ingat keputusan untuk pasangan ekstensi ini.

**Parameter:** kualitas JPEG/HEIC/AVIF/WebP; untuk video — codec (tanpa encoding ulang / H.264 / HEVC),
resolusi (4K…480p, tidak pernah diperbesar), frame rate, penghapusan lokasi dan metadata pribadi;
frame rate dan lebar GIF; bitrate AAC/MP3; ukuran halaman PDF.

**Pembaruan:** tombol "Periksa Pembaruan" dan pemeriksaan otomatis harian melalui
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). Pembaruan diunduh,
diverifikasi dengan SHA-256 dan tanda tangan kode, lalu diinstal dengan meluncurkan ulang aplikasi.

**Laporan bug:** menu → "Laporkan Bug…" (atau tombol di notifikasi kesalahan) membuat email ke
pengembang berisi deskripsi Anda, info sistem, dan log aplikasi sebagai lampiran. Log:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 bahasa:** Inggris, Rusia, Jerman, Prancis, Spanyol, Italia, Portugis (Brasil), Belanda, Polandia,
Ukraina, Ceko, Swedia, Turki, Arab, Ibrani, Hindi, Indonesia, Vietnam, Thai, Jepang, Korea,
Tionghoa (Sederhana dan Tradisional).

**Juga:** folder yang dipantau dan pengecualian, progres dan pembatalan di bar menu, riwayat dengan "Kembalikan Asli",
file asli dipindahkan ke Tong Sampah, notifikasi, buka saat masuk. Semuanya berjalan secara lokal — file tidak pernah meninggalkan Mac Anda.

## Membangun

Memerlukan macOS 15+ dan Command Line Tools (`xcode-select --install`). Xcode bersifat opsional,
tetapi proyek dapat dibuka di dalamnya sebagai paket Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universal: Apple Silicon + Intel); membangun FFmpeg pada eksekusi pertama (~15 menit)
./build.sh install    # instal ke ~/Applications dan jalankan
./build.sh dist       # build/RenameConvert.zip (untuk pembaruan otomatis) dan build/RenameConvert.dmg
./build.sh release    # dist + terbitkan rilis v<version> di GitHub
```

Terjemahan: `scripts/extract-strings.py` mengumpulkan string UI ke `Resources/Localization/keys.json`;
`--check` memverifikasi bahwa setiap bahasa memiliki semua string dengan placeholder yang cocok.
Video promo: `scripts/promo/make-promo.sh` (sulih suara dengan `say`, bingkai SwiftUI, digabungkan dengan FFmpeg).

## Arsitektur

| File | Fungsi |
|---|---|
| `RenameWatcher.swift` | FSEvents: menangkap pasangan "nama lama → nama baru" |
| `Formats.swift` | Registri format: mesin mana yang menangani pasangan ekstensi |
| `Rules.swift` | Aturan dan parameter konversi |
| `Pipeline.swift` | Folder kerja, menjalankan mesin, file asli ke Tong Sampah, penggantian atomik |
| `Engines/ImageEngine.swift` | Gambar (ImageIO), PDF → gambar |
| `Engines/MediaEngine.swift` | Video, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Dokumen (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, arsip (bsdtar), kesalahan bersama |
| `Engines/FFmpegEngine.swift` | FFmpeg bawaan: WebP, MP3, MKV, AVI, WebM, OGG, GIF dengan palet |
| `Updater.swift` | Memeriksa dan menginstal pembaruan dari GitHub Releases |
| `BugReport.swift`, `Log.swift` | Laporan bug melalui email, log aplikasi |
| `AppModel.swift` | Pengaturan, antrean, permintaan konfirmasi, riwayat, notifikasi |
| `AskPanel.swift`, `ParamsForm.swift` | Panel konfirmasi dan formulir parameter |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu di bar menu dan jendela pengaturan |

## Lisensi komponen yang disertakan

FFmpeg disertakan sebagai file eksekusi terpisah (`Contents/Helpers/ffmpeg`) di bawah LGPL 2.1, dibangun dengan LAME (LGPL)
dan libwebp (BSD). Teks lisensinya ada di `Contents/Resources/Licenses`; skrip build yang persis adalah
`scripts/build-ffmpeg.sh`.
