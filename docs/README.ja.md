<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · **日本語** · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

macOS のメニューバーアプリです。Finder でファイルの拡張子を変更すると、ファイル形式も変換されます。
`photo.heic` → `photo.jpg`、`clip.mov` → `clip.mp4`、`clip.mov` → `clip.gif`、`report.docx` → `report.pdf`。

![アイコン](../Resources/AppIcon.png)

## インストール

[最新リリース](https://github.com/Kohinor46/RenameConvert/releases/latest)から **RenameConvert.dmg** をダウンロードし、
アプリを「アプリケーション」フォルダにドラッグしてください。macOS 15 以降、Apple Silicon または Intel が必要です。

アプリは公証（notarize）されていないため、初回起動時に macOS によってブロックされます。アプリを右クリック → **開く**
（または「システム設定」→「プライバシーとセキュリティ」で **このまま開く**）を選択してください。

## 機能

| カテゴリ | 変換元 | 変換先 |
|---|---|---|
| 画像 | jpg、png、heic、webp、gif、tiff、bmp、RAW など | jpg、png、heic、avif、**webp**、gif、tiff、bmp、jp2、ico、icns、psd、tga、pdf |
| ビデオ | mov、mp4、m4v、3gp、**mkv、avi、webm、flv、wmv、mpg、ts、mts、ogv** | mov、mp4、m4v、**mkv** · **gif** · オーディオ（m4a、**mp3**、wav、aiff、caf、flac） · フレーム（jpg、png…） |
| GIF | gif | mp4、mov、m4v、webp（アニメーション） |
| オーディオ | mp3、m4a、aac、wav、aiff、caf、flac、**ogg、opus、wma、ac3、amr、ape** | m4a、**mp3**、wav、aiff、caf、flac |
| 書類 | txt、rtf、html、docx、doc、odt、webarchive、pdf | txt、rtf、html、docx、doc、odt、pdf · PDF → 画像（1 ページ目） |
| データ | json、plist | json、plist |
| アーカイブ | zip、tar、tar.gz、tar.bz2、tar.xz、7z | 同じ形式 |

macOS 単体では扱えない形式（WebP、MP3、MKV、AVI、WebM、OGG…）は、内蔵の **FFmpeg 7.1**
（LGPL 2.1、LAME と libwebp を含む）で変換されます。FFmpeg は `scripts/build-ffmpeg.sh` によって公式ソースから
SHA-256 検証付きでビルドされ、システムライブラリのみに依存します。

**ルール。** 「変換元 → 変換先」の組み合わせ（拡張子、カテゴリ、または「すべて」）ごとに動作を選べます。
先に確認する、すぐに変換する、変換しない、そしてオリジナルを残すかどうか。
より具体的なルールが優先されます。デフォルトでは、ビデオは「確認する」、それ以外はすべて「すぐに変換」です。

**確認パネル**は画面右上に表示されます。この変換に限ってパラメータを変更したり、
この拡張子の組み合わせに対する選択を記憶させたりできます。

**パラメータ：** JPEG/HEIC/AVIF/WebP の品質。ビデオの場合はコーデック（再エンコードなし / H.264 / HEVC）、
解像度（4K…480p、アップスケールはしません）、フレームレート、位置情報や個人のメタデータの削除。
GIF のフレームレートと幅。AAC/MP3 のビットレート。PDF のページサイズ。

**アップデート：**「アップデートを確認」ボタンと、[GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases)
に対する毎日の自動チェック。アップデートはダウンロード後、SHA-256 とコード署名で検証され、再起動とともにインストールされます。

**バグ報告：** メニュー →「バグを報告…」（またはエラー通知内のボタン）で、開発者宛てのメールが作成されます。
メールにはあなたの説明、システム情報、アプリのログが添付されます。ログ：
`~/Library/Logs/RenameConvert/RenameConvert.log`。

**23 言語：** 英語、ロシア語、ドイツ語、フランス語、スペイン語、イタリア語、ポルトガル語（ブラジル）、オランダ語、ポーランド語、
ウクライナ語、チェコ語、スウェーデン語、トルコ語、アラビア語、ヘブライ語、ヒンディー語、インドネシア語、ベトナム語、タイ語、日本語、韓国語、
中国語（簡体字および繁体字）。

**その他：** 監視フォルダと除外設定、メニューバーでの進捗表示とキャンセル、「オリジナルに戻す」付きの履歴、
オリジナルのゴミ箱への移動、通知、ログイン時の起動。すべての処理はローカルで行われ、ファイルが Mac の外に出ることはありません。

## ビルド

macOS 15 以降と Command Line Tools（`xcode-select --install`）が必要です。Xcode は必須ではありませんが、
プロジェクトを Swift パッケージとして Xcode で開くこともできます（`open Package.swift`）。

```bash
./build.sh            # build/RenameConvert.app（ユニバーサル：Apple Silicon + Intel）。初回実行時に FFmpeg をビルド（約 15 分）
./build.sh install    # ~/Applications にインストールして起動
./build.sh dist       # build/RenameConvert.zip（自動アップデート用）と build/RenameConvert.dmg
./build.sh release    # dist + GitHub でリリース v<version> を公開
```

翻訳：`scripts/extract-strings.py` が UI 文字列を `Resources/Localization/keys.json` に収集します。
`--check` は、すべての言語にすべての文字列があり、プレースホルダが一致していることを検証します。
プロモーション動画：`scripts/promo/make-promo.sh`（`say` によるナレーション、SwiftUI のフレーム、FFmpeg で結合）。

## アーキテクチャ

| ファイル | 役割 |
|---|---|
| `RenameWatcher.swift` | FSEvents：「旧ファイル名 → 新ファイル名」の組み合わせを検出 |
| `Formats.swift` | 形式レジストリ：拡張子の組み合わせをどのエンジンが処理するか |
| `Rules.swift` | ルールと変換パラメータ |
| `Pipeline.swift` | 作業フォルダ、エンジンの実行、オリジナルをゴミ箱へ、アトミックな置き換え |
| `Engines/ImageEngine.swift` | 画像（ImageIO）、PDF → 画像 |
| `Engines/MediaEngine.swift` | ビデオ、GIF、オーディオ（AVFoundation、afconvert） |
| `Engines/DocumentEngine.swift` | 書類（NSAttributedString、PDFKit、CoreText） |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist、アーカイブ（bsdtar）、共通エラー |
| `Engines/FFmpegEngine.swift` | 内蔵 FFmpeg：WebP、MP3、MKV、AVI、WebM、OGG、パレット GIF |
| `Updater.swift` | GitHub Releases からのアップデートの確認とインストール |
| `BugReport.swift`、`Log.swift` | メールによるバグ報告、アプリのログ |
| `AppModel.swift` | 設定、キュー、確認、履歴、通知 |
| `AskPanel.swift`、`ParamsForm.swift` | 確認パネルとパラメータフォーム |
| `RenameConvertApp.swift`、`SettingsView.swift` | メニューバーのメニューと設定ウインドウ |

## 同梱コンポーネントのライセンス

FFmpeg は LGPL 2.1 のもと、独立した実行ファイル（`Contents/Helpers/ffmpeg`）として同梱されており、LAME（LGPL）と
libwebp（BSD）を組み込んでビルドされています。各ライセンス文は `Contents/Resources/Licenses` にあり、実際のビルドスクリプトは
`scripts/build-ffmpeg.sh` です。
