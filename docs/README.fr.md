<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · **Français** · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

Une app pour la barre des menus de macOS : changez l’extension d’un fichier dans le Finder, et son format change aussi.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![Icône](../Resources/AppIcon.png)

## Installation

Téléchargez **RenameConvert.dmg** depuis la [dernière version](https://github.com/Kohinor46/RenameConvert/releases/latest)
et faites glisser l’app dans le dossier Applications. Nécessite macOS 15 ou ultérieur, Apple Silicon ou Intel.

L’app n’est pas notarisée, macOS bloque donc le premier lancement : clic droit sur l’app → **Ouvrir**
(ou **Ouvrir quand même** dans Réglages Système → Confidentialité et sécurité).

## Soutenir le projet

RenameConvert est gratuit. S’il vous fait gagner du temps, vous pouvez soutenir son développement :

- **Carte bancaire (banques russes) :** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, réseau TON uniquement :** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ Envoyez uniquement des USDT sur le réseau TON : d’autres cryptomonnaies ou réseaux risquent d’être perdus.

Les mêmes options, avec un code QR, sont disponibles dans l’app : menu → « Soutenir le projet ♥… ».

## Fonctionnalités

| Catégorie | Depuis | Vers |
|---|---|---|
| Images | jpg, png, heic, webp, gif, tiff, bmp, RAW et plus | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| Vidéo | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · audio (m4a, **mp3**, wav, aiff, caf, flac) · image fixe (jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp (animé) |
| Audio | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| Documents | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → image (première page) |
| Données | json, plist | json, plist |
| Archives | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | les mêmes |

Les formats que macOS ne sait pas gérer seul (WebP, MP3, MKV, AVI, WebM, OGG…) sont convertis par
**FFmpeg 7.1** intégré (LGPL 2.1, avec LAME et libwebp). Il est compilé à partir des sources officielles par `scripts/build-ffmpeg.sh`,
avec vérification SHA-256, et ne dépend que des bibliothèques système.

**Règles.** Pour chaque paire « source → cible » (une extension, une catégorie ou « n’importe laquelle »), vous choisissez ce qui se passe :
demander d’abord, convertir tout de suite ou ne pas convertir — et s’il faut conserver l’original.
La règle la plus précise l’emporte ; par défaut, la vidéo est sur « Demander » et tout le reste sur « Convertir immédiatement ».

**Panneau de confirmation** : il apparaît dans le coin supérieur droit ; modifiez les paramètres de cette conversion précise
et mémorisez la décision pour cette paire d’extensions.

**Paramètres :** qualité JPEG/HEIC/AVIF/WebP ; pour la vidéo — codec (sans réencodage / H.264 / HEVC),
résolution (4K…480p, jamais agrandie), fréquence d’images, suppression de la localisation et des métadonnées personnelles ;
fréquence d’images et largeur des GIF ; débit AAC/MP3 ; format de page PDF.

**Mises à jour :** un bouton « Rechercher les mises à jour » et une vérification quotidienne automatique via
[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases). La mise à jour est téléchargée,
vérifiée par SHA-256 et signature de code, puis installée avec un redémarrage de l’app.

**Signalement de bug :** menu → « Signaler un bug… » (ou le bouton d’une notification d’erreur) crée un e-mail au
développeur avec votre description, les informations système et le journal de l’app en pièce jointe. Journal :
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23 langues :** anglais, russe, allemand, français, espagnol, italien, portugais (Brésil), néerlandais, polonais,
ukrainien, tchèque, suédois, turc, arabe, hébreu, hindi, indonésien, vietnamien, thaï, japonais, coréen,
chinois (simplifié et traditionnel).

**Et aussi :** dossiers surveillés et exclusions, progression et annulation dans la barre des menus, historique avec « Restaurer l’original »,
originaux placés dans la Corbeille, notifications, lancement à l’ouverture de session. Tout s’exécute localement — vos fichiers ne quittent jamais votre Mac.

## Compilation

Nécessite macOS 15+ et les Command Line Tools (`xcode-select --install`). Xcode est facultatif,
mais le projet s’y ouvre comme un package Swift (`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (universelle : Apple Silicon + Intel) ; compile FFmpeg au premier lancement (~15 min)
./build.sh install    # installer dans ~/Applications et lancer
./build.sh dist       # build/RenameConvert.zip (pour la mise à jour automatique) et build/RenameConvert.dmg
./build.sh release    # dist + publication de la version v<version> sur GitHub
```

Traductions : `scripts/extract-strings.py` rassemble les chaînes de l’interface dans `Resources/Localization/keys.json` ;
`--check` vérifie que chaque langue contient toutes les chaînes avec des espaces réservés correspondants.
Vidéos promotionnelles : `scripts/promo/make-promo.sh` (voix off avec `say`, images SwiftUI, assemblage avec FFmpeg).

## Architecture

| Fichier | Rôle |
|---|---|
| `RenameWatcher.swift` | FSEvents : détecte les paires « ancien nom → nouveau nom » |
| `Formats.swift` | Registre des formats : quel moteur gère une paire d’extensions |
| `Rules.swift` | Règles et paramètres de conversion |
| `Pipeline.swift` | Dossier de travail, exécution du moteur, original dans la Corbeille, remplacement atomique |
| `Engines/ImageEngine.swift` | Images (ImageIO), PDF → image |
| `Engines/MediaEngine.swift` | Vidéo, GIF, audio (AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | Documents (NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, archives (bsdtar), erreurs communes |
| `Engines/FFmpegEngine.swift` | FFmpeg intégré : WebP, MP3, MKV, AVI, WebM, OGG, GIF avec palette |
| `Updater.swift` | Recherche et installation des mises à jour depuis GitHub Releases |
| `BugReport.swift`, `Log.swift` | Signalement de bug par e-mail, journal de l’app |
| `AppModel.swift` | Réglages, file d’attente, demandes, historique, notifications |
| `AskPanel.swift`, `ParamsForm.swift` | Panneau de confirmation et formulaire des paramètres |
| `RenameConvertApp.swift`, `SettingsView.swift` | Menu de la barre des menus et fenêtre des réglages |

## Licence des composants inclus

FFmpeg est inclus sous forme d’exécutable séparé (`Contents/Helpers/ffmpeg`) sous licence LGPL 2.1, compilé avec LAME (LGPL)
et libwebp (BSD). Les textes de leurs licences se trouvent dans `Contents/Resources/Licenses` ; le script de compilation exact est
`scripts/build-ffmpeg.sh`.
