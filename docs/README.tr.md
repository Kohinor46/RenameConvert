<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · **Türkçe** · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

macOS için bir menü çubuğu uygulaması: Finder’da bir dosyanın uzantısını değiştirin, biçimi de değişsin.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Simge](../Resources/AppIcon.png)

## Kurulum

**RenameConvert.dmg** dosyasını [son sürümden](https://github.com/Kohinor46/RenameConvert/releases/latest) indirin
ve uygulamayı Uygulamalar klasörüne sürükleyin. macOS 15 veya sonrası, Apple Silicon ya da Intel gerektirir.

Uygulama noter onaylı olmadığından macOS ilk açılışı engeller: uygulamaya sağ tıklayın → **Aç**
(ya da Sistem Ayarları → Gizlilik ve Güvenlik bölümünde **Yine de Aç**).

## Projeyi destekleyin

RenameConvert ücretsizdir. Size zaman kazandırıyorsa geliştirmeyi destekleyebilirsiniz:

- **Banka kartı (Rus bankaları):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, yalnızca TON ağı:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Yalnızca TON ağında USDT gönderin — diğer coin'ler veya ağlar kaybolabilir.

Aynı seçenekler, QR koduyla birlikte, uygulamada da var: menü → "Projeyi Destekle ♥…".

## Özellikler

| Kategori | Kaynak | Hedef |
|---|---|---|
| Görüntüler | jpg, png, heic, webp, gif, tiff, bmp, RAW ve diğerleri | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Video | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · ses (m4a, **mp3**, wav, aiff, caf, flac) · kare (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (hareketli) |
| Ses | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Belgeler | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → görüntü (ilk sayfa) |
| Veri | json, plist | json, plist |
| Arşivler | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | aynıları |

macOS’in kendi başına işleyemediği biçimler (WebP, MP3, MKV, AVI, WebM, OGG…) yerleşik
**FFmpeg 7.1** (LGPL 2.1, LAME ve libwebp ile) tarafından dönüştürülür. FFmpeg, `scripts/build-ffmpeg.sh` ile resmî kaynaklardan
SHA-256 denetimleriyle derlenir ve yalnızca sistem kitaplıklarına bağımlıdır.

**Kurallar.** Her “kaynak → hedef” çifti için (bir uzantı, bir kategori ya da “herhangi biri”) ne olacağını siz seçersiniz:
önce sor, hemen dönüştür ya da dönüştürme — ve orijinalin saklanıp saklanmayacağı.
En özgül kural geçerli olur; varsayılan olarak video için “Sor”, diğer her şey için “Hemen Dönüştür” seçilidir.

**Onay paneli** sağ üst köşede görünür: bu dönüştürmeye özel parametreleri değiştirin
ve bu uzantı çifti için kararınızı hatırlatın.

**Parametreler:** JPEG/HEIC/AVIF/WebP kalitesi; video için — kodek (yeniden kodlamadan / H.264 / HEVC),
çözünürlük (4K…480p, asla büyütülmez), kare hızı, konum ve kişisel meta verilerin kaldırılması;
GIF kare hızı ve genişliği; AAC/MP3 bit hızı; PDF sayfa boyutu.

**Güncellemeler:** “Güncellemeleri Denetle” düğmesi ve
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases) üzerinden günlük otomatik denetim. Güncelleme indirilir,
SHA-256 ve kod imzasıyla doğrulanır ve uygulama yeniden başlatılarak kurulur.

**Hata bildirimi:** menü → “Hata Bildir…” (ya da hata bildirimindeki düğme), açıklamanızı, sistem bilgilerini
ve ekli uygulama günlüğünü içeren, geliştiriciye yönelik bir e-posta oluşturur. Günlük:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 dil:** İngilizce, Rusça, Almanca, Fransızca, İspanyolca, İtalyanca, Portekizce (Brezilya), Felemenkçe, Lehçe,
Ukraynaca, Çekçe, İsveççe, Türkçe, Arapça, İbranice, Hintçe, Endonezce, Vietnamca, Tayca, Japonca, Korece,
Çince (Basitleştirilmiş ve Geleneksel).

**Ayrıca:** izlenen klasörler ve hariç tutulanlar, menü çubuğunda ilerleme ve iptal, “Orijinali Geri Yükle” özellikli geçmiş,
orijinallerin Çöp Sepeti’ne taşınması, bildirimler, oturum açılışında başlatma. Her şey yerel olarak çalışır — dosyalar Mac’inizden asla çıkmaz.

## Derleme

macOS 15+ ve Command Line Tools (`xcode-select --install`) gerekir. Xcode isteğe bağlıdır,
ancak proje Xcode’da bir Swift paketi olarak açılabilir (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (evrensel: Apple Silicon + Intel); ilk çalıştırmada FFmpeg’i derler (~15 dk)
./build.sh install    # ~/Applications konumuna kur ve başlat
./build.sh dist       # build/RenameConvert.zip (otomatik güncelleme için) ve build/RenameConvert.dmg
./build.sh release    # dist + GitHub’da v<sürüm> sürümünü yayımla
```

Çeviriler: `scripts/extract-strings.py` arayüz dizelerini `Resources/Localization/keys.json` dosyasında toplar;
`--check` her dilde tüm dizelerin eşleşen yer tutucularla bulunduğunu doğrular.
Tanıtım videoları: `scripts/promo/make-promo.sh` (`say` ile seslendirme, SwiftUI kareleri, FFmpeg ile birleştirme).

## Mimari

| Dosya | Amaç |
|---|---|
| `RenameWatcher.swift` | FSEvents: “eski ad → yeni ad” çiftlerini yakalar |
| `Formats.swift` | Biçim kaydı: bir uzantı çiftini hangi motorun işlediği |
| `Rules.swift` | Kurallar ve dönüştürme parametreleri |
| `Pipeline.swift` | Çalışma klasörü, motorun çalıştırılması, orijinalin Çöp Sepeti’ne taşınması, atomik değiştirme |
| `Engines/ImageEngine.swift` | Görüntüler (ImageIO), PDF → görüntü |
| `Engines/MediaEngine.swift` | Video, GIF, ses (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Belgeler (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, arşivler (bsdtar), ortak hatalar |
| `Engines/FFmpegEngine.swift` | Yerleşik FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, paletli GIF’ler |
| `Updater.swift` | GitHub Releases’tan güncellemeleri denetleme ve kurma |
| `BugReport.swift`, `Log.swift` | E-postayla hata bildirimi, uygulama günlüğü |
| `AppModel.swift` | Ayarlar, kuyruk, sorular, geçmiş, bildirimler |
| `AskPanel.swift`, `ParamsForm.swift` | Onay paneli ve parametre formu |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menü çubuğu menüsü ve ayarlar penceresi |

## Birlikte gelen bileşenlerin lisansı

FFmpeg, LGPL 2.1 kapsamında ayrı bir çalıştırılabilir dosya (`Contents/Helpers/ffmpeg`) olarak dahil edilmiştir ve LAME (LGPL)
ile libwebp (BSD) kullanılarak derlenmiştir. Lisans metinleri `Contents/Resources/Licenses` içindedir; tam derleme betiği
`scripts/build-ffmpeg.sh` dosyasıdır.
