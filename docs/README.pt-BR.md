<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · **Português (Brasil)** · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Um app para a barra de menus do macOS: altere a extensão de um arquivo no Finder e o formato dele muda junto.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Ícone](../Resources/AppIcon.png)

## Instalação

Baixe **RenameConvert.dmg** da [versão mais recente](https://github.com/Kohinor46/RenameConvert/releases/latest)
e arraste o app para Aplicativos. Requer macOS 15 ou posterior, Apple Silicon ou Intel.

O app não é notarizado, por isso o macOS bloqueia a primeira abertura: clique com o botão direito no app → **Abrir**
(ou **Abrir Mesmo Assim** em Ajustes do Sistema → Privacidade e Segurança).

## Recursos

| Categoria | De | Para |
|---|---|---|
| Imagens | jpg, png, heic, webp, gif, tiff, bmp, RAW e outros | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Vídeo | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · áudio (m4a, **mp3**, wav, aiff, caf, flac) · quadro (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animado) |
| Áudio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documentos | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → imagem (primeira página) |
| Dados | json, plist | json, plist |
| Arquivos compactados | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | os mesmos |

Formatos que o macOS não consegue processar sozinho (WebP, MP3, MKV, AVI, WebM, OGG…) são convertidos pelo
**FFmpeg 7.1** integrado (LGPL 2.1, com LAME e libwebp). Ele é compilado a partir das fontes oficiais pelo `scripts/build-ffmpeg.sh`,
com verificação SHA-256, e depende apenas de bibliotecas do sistema.

**Regras.** Para qualquer par "de → para" (uma extensão, uma categoria ou "qualquer") você escolhe o que acontece:
perguntar antes, converter na hora ou não converter — e se o original deve ser mantido.
A regra mais específica prevalece; por padrão, vídeo fica em "Perguntar" e todo o resto em "Converter Imediatamente".

**Painel de confirmação:** aparece no canto superior direito; altere os parâmetros desta conversão específica
e memorize a decisão para este par de extensões.

**Parâmetros:** qualidade de JPEG/HEIC/AVIF/WebP; para vídeo — codec (sem recodificação / H.264 / HEVC),
resolução (4K…480p, nunca ampliada), taxa de quadros, remoção de localização e de metadados pessoais;
taxa de quadros e largura de GIF; taxa de bits de AAC/MP3; tamanho de página de PDF.

**Atualizações:** um botão "Buscar Atualizações" e uma verificação diária automática no
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). A atualização é baixada,
verificada por SHA-256 e assinatura de código, e instalada com a reabertura do app.

**Relatório de erros:** menu → "Relatar um Erro…" (ou o botão em uma notificação de erro) cria um e-mail para o
desenvolvedor com a sua descrição, informações do sistema e o log do app anexado. Log:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 idiomas:** inglês, russo, alemão, francês, espanhol, italiano, português (Brasil), holandês, polonês,
ucraniano, tcheco, sueco, turco, árabe, hebraico, híndi, indonésio, vietnamita, tailandês, japonês, coreano,
chinês (simplificado e tradicional).

**Além disso:** pastas monitoradas e exclusões, progresso e cancelamento na barra de menus, histórico com "Restaurar Original",
originais movidos para o Lixo, notificações, abertura ao iniciar a sessão. Tudo é executado localmente — os arquivos nunca saem do seu Mac.

## Compilação

Requer macOS 15+ e as Command Line Tools (`xcode-select --install`). O Xcode é opcional,
mas o projeto pode ser aberto nele como um pacote Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universal: Apple Silicon + Intel); compila o FFmpeg na primeira execução (~15 min)
./build.sh install    # instala em ~/Applications e abre
./build.sh dist       # build/RenameConvert.zip (para a atualização automática) e build/RenameConvert.dmg
./build.sh release    # dist + publica a versão v<version> no GitHub
```

Traduções: `scripts/extract-strings.py` coleta as strings da interface em `Resources/Localization/keys.json`;
`--check` verifica se cada idioma tem todas as strings com os marcadores correspondentes.
Vídeos promocionais: `scripts/promo/make-promo.sh` (narração com `say`, quadros em SwiftUI, multiplexados com FFmpeg).

## Arquitetura

| Arquivo | Finalidade |
|---|---|
| `RenameWatcher.swift` | FSEvents: captura pares "nome antigo → nome novo" |
| `Formats.swift` | Registro de formatos: qual mecanismo processa um par de extensões |
| `Rules.swift` | Regras e parâmetros de conversão |
| `Pipeline.swift` | Pasta de trabalho, execução do mecanismo, original para o Lixo, substituição atômica |
| `Engines/ImageEngine.swift` | Imagens (ImageIO), PDF → imagem |
| `Engines/MediaEngine.swift` | Vídeo, GIF, áudio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documentos (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, arquivos compactados (bsdtar), erros compartilhados |
| `Engines/FFmpegEngine.swift` | FFmpeg integrado: WebP, MP3, MKV, AVI, WebM, OGG, GIFs com paleta |
| `Updater.swift` | Verificação e instalação de atualizações do GitHub Releases |
| `BugReport.swift`, `Log.swift` | Relatório de erros por e-mail, log do app |
| `AppModel.swift` | Ajustes, fila, perguntas, histórico, notificações |
| `AskPanel.swift`, `ParamsForm.swift` | Painel de confirmação e formulário de parâmetros |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu da barra de menus e janela de ajustes |

## Licença dos componentes incluídos

O FFmpeg é incluído como um executável separado (`Contents/Helpers/ffmpeg`) sob a LGPL 2.1, compilado com LAME (LGPL)
e libwebp (BSD). Os textos das licenças estão em `Contents/Resources/Licenses`; o script de compilação exato é
`scripts/build-ffmpeg.sh`.
