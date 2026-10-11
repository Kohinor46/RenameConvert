<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · **Español** · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Una app para la barra de menús de macOS: cambia la extensión de un archivo en el Finder y su formato cambia también.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Icono](../Resources/AppIcon.png)

## Instalación

Descarga **RenameConvert.dmg** desde la [última versión](https://github.com/Kohinor46/RenameConvert/releases/latest)
y arrastra la app a Aplicaciones. Requiere macOS 15 o posterior, Apple Silicon o Intel.

La app no está notarizada, por lo que macOS bloquea el primer arranque: haz clic derecho en la app → **Abrir**
(o **Abrir igualmente** en Ajustes del Sistema → Privacidad y seguridad).

## Apoyar el proyecto

RenameConvert es gratuito. Si te ahorra tiempo, puedes apoyar su desarrollo:

- **Tarjeta bancaria (bancos rusos):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, solo red TON:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Envía solo USDT en la red TON: otras monedas o redes podrían perderse.

Las mismas opciones, con un código QR, están en la app: menú → «Apoyar el proyecto ♥…».

## Funciones

| Categoría | De | A |
|---|---|---|
| Imágenes | jpg, png, heic, webp, gif, tiff, bmp, RAW y más | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Vídeo | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · fotograma (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animado) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documentos | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → imagen (primera página) |
| Datos | json, plist | json, plist |
| Archivos comprimidos | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | los mismos |

Los formatos que macOS no puede manejar por sí solo (WebP, MP3, MKV, AVI, WebM, OGG…) se convierten con
**FFmpeg 7.1** integrado (LGPL 2.1, con LAME y libwebp). Se compila a partir de las fuentes oficiales con `scripts/build-ffmpeg.sh`,
con verificación SHA-256, y solo depende de bibliotecas del sistema.

**Reglas.** Para cualquier par «origen → destino» (una extensión, una categoría o «cualquiera») eliges qué ocurre:
preguntar primero, convertir al momento o no convertir, y si se conserva el original.
Gana la regla más específica; por omisión, el vídeo está en «Preguntar» y todo lo demás en «Convertir al instante».

**Panel de confirmación:** aparece en la esquina superior derecha; cambia los parámetros de esta conversión concreta
y recuerda la decisión para este par de extensiones.

**Parámetros:** calidad de JPEG/HEIC/AVIF/WebP; para vídeo: códec (sin recodificar / H.264 / HEVC),
resolución (4K…480p, nunca se amplía), frecuencia de fotogramas, eliminación de la ubicación y de los metadatos personales;
frecuencia de fotogramas y ancho de los GIF; tasa de bits de AAC/MP3; tamaño de página del PDF.

**Actualizaciones:** un botón «Buscar actualizaciones» y una comprobación diaria automática en
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). La actualización se descarga,
se verifica mediante SHA-256 y la firma de código, y se instala reiniciando la app.

**Informe de errores:** menú → «Informar de un error…» (o el botón de una notificación de error) crea un correo al
desarrollador con tu descripción, la información del sistema y el registro de la app adjunto. Registro:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 idiomas:** inglés, ruso, alemán, francés, español, italiano, portugués (Brasil), neerlandés, polaco,
ucraniano, checo, sueco, turco, árabe, hebreo, hindi, indonesio, vietnamita, tailandés, japonés, coreano,
chino (simplificado y tradicional).

**Además:** carpetas vigiladas y exclusiones, progreso y cancelación en la barra de menús, historial con «Restaurar original»,
originales enviados a la Papelera, notificaciones, apertura al iniciar sesión. Todo se ejecuta en local: tus archivos nunca salen de tu Mac.

## Compilación

Requiere macOS 15+ y las Command Line Tools (`xcode-select --install`). Xcode es opcional,
pero el proyecto se abre en él como paquete Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universal: Apple Silicon + Intel); compila FFmpeg en la primera ejecución (~15 min)
./build.sh install    # instalar en ~/Applications y abrir
./build.sh dist       # build/RenameConvert.zip (para la actualización automática) y build/RenameConvert.dmg
./build.sh release    # dist + publicar la versión v<version> en GitHub
```

Traducciones: `scripts/extract-strings.py` recopila las cadenas de la interfaz en `Resources/Localization/keys.json`;
`--check` comprueba que cada idioma tenga todas las cadenas con los marcadores de posición correspondientes.
Vídeos promocionales: `scripts/promo/make-promo.sh` (locución con `say`, fotogramas en SwiftUI, multiplexado con FFmpeg).

## Arquitectura

| Archivo | Función |
|---|---|
| `RenameWatcher.swift` | FSEvents: detecta los pares «nombre antiguo → nombre nuevo» |
| `Formats.swift` | Registro de formatos: qué motor gestiona un par de extensiones |
| `Rules.swift` | Reglas y parámetros de conversión |
| `Pipeline.swift` | Carpeta de trabajo, ejecución del motor, original a la Papelera, sustitución atómica |
| `Engines/ImageEngine.swift` | Imágenes (ImageIO), PDF → imagen |
| `Engines/MediaEngine.swift` | Vídeo, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documentos (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archivos comprimidos (bsdtar), errores comunes |
| `Engines/FFmpegEngine.swift` | FFmpeg integrado: WebP, MP3, MKV, AVI, WebM, OGG, GIF con paleta |
| `Updater.swift` | Búsqueda e instalación de actualizaciones desde GitHub Releases |
| `BugReport.swift`, `Log.swift` | Informe de errores por correo, registro de la app |
| `AppModel.swift` | Ajustes, cola, preguntas, historial, notificaciones |
| `AskPanel.swift`, `ParamsForm.swift` | Panel de confirmación y formulario de parámetros |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menú de la barra de menús y ventana de ajustes |

## Licencia de los componentes incluidos

FFmpeg se incluye como ejecutable independiente (`Contents/Helpers/ffmpeg`) bajo LGPL 2.1, compilado con LAME (LGPL)
y libwebp (BSD). Los textos de sus licencias están en `Contents/Resources/Licenses`; el script de compilación exacto es
`scripts/build-ffmpeg.sh`.
