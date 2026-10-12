<!-- languages -->
🌐 [English](../README.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md) · [Українська](README.uk.md) · [Čeština](README.cs.md) · [Svenska](README.sv.md) · [Türkçe](README.tr.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [ไทย](README.th.md) · [日本語](README.ja.md) · **한국어** · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)
<!-- /languages -->

# RenameConvert

macOS 메뉴 막대 앱입니다. Finder에서 파일 확장자를 바꾸면 파일 형식도 함께 바뀝니다.
`photo.heic` → `photo.jpg`, `clip.mov` → `clip.mp4`, `clip.mov` → `clip.gif`, `report.docx` → `report.pdf`.

![아이콘](../Resources/AppIcon.png)

## 설치

[최신 릴리스](https://github.com/Kohinor46/RenameConvert/releases/latest)에서 **RenameConvert.dmg**를 다운로드한 다음
앱을 응용 프로그램 폴더로 드래그하세요. macOS 15 이상, Apple Silicon 또는 Intel이 필요합니다.

앱이 공증(notarization)되지 않았기 때문에 macOS가 첫 실행을 차단합니다. 앱을 오른쪽 클릭 → **열기**를 선택하세요
(또는 시스템 설정 → 개인정보 보호 및 보안에서 **그래도 열기**).

## 프로젝트 후원

RenameConvert는 무료입니다. 시간을 절약하는 데 도움이 된다면 개발을 후원할 수 있습니다:

- **은행 카드(러시아 은행):** [CloudTips](https://pay.cloudtips.ru/p/253eb33a)
- **USDT, TON 네트워크만:** `UQBSrz9r4NLiwa13oLu6pmEJVcxldyPba81lkBys5bnhgzJg`
  ⚠️ TON 네트워크의 USDT만 보내십시오. 다른 코인이나 네트워크로 보내면 잃을 수 있습니다.

같은 방법을 QR 코드와 함께 앱에서도 이용할 수 있습니다: 메뉴 → "프로젝트 후원하기 ♥…".

## 기능

| 카테고리 | 원본 | 변환 대상 |
|---|---|---|
| 이미지 | jpg, png, heic, webp, gif, tiff, bmp, RAW 등 | jpg, png, heic, avif, **webp**, gif, tiff, bmp, jp2, ico, icns, psd, tga, pdf |
| 비디오 | mov, mp4, m4v, 3gp, **mkv, avi, webm, flv, wmv, mpg, ts, mts, ogv** | mov, mp4, m4v, **mkv** · **gif** · 오디오(m4a, **mp3**, wav, aiff, caf, flac) · 프레임(jpg, png…) |
| GIF | gif | mp4, mov, m4v, webp(애니메이션) |
| 오디오 | mp3, m4a, aac, wav, aiff, caf, flac, **ogg, opus, wma, ac3, amr, ape** | m4a, **mp3**, wav, aiff, caf, flac |
| 문서 | txt, rtf, html, docx, doc, odt, webarchive, pdf | txt, rtf, html, docx, doc, odt, pdf · PDF → 이미지(첫 페이지) |
| 데이터 | json, plist | json, plist |
| 아카이브 | zip, tar, tar.gz, tar.bz2, tar.xz, 7z | 동일 형식 |

macOS가 자체적으로 처리하지 못하는 형식(WebP, MP3, MKV, AVI, WebM, OGG…)은 내장된
**FFmpeg 7.1**(LGPL 2.1, LAME 및 libwebp 포함)로 변환됩니다. FFmpeg는 `scripts/build-ffmpeg.sh`를 통해 공식 소스에서
SHA-256 검증을 거쳐 빌드되며, 시스템 라이브러리에만 의존합니다.

**Finder 컨텍스트 메뉴:** 파일(여러 개도 가능)을 오른쪽 클릭 → **다음으로 변환** → 포맷 선택.
확장자를 바꾼 것처럼 파일이 바로 변환됩니다. Finder 확장 프로그램은 처음 실행할 때 켜집니다.
시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램(또는 앱의 설정 → ‘Finder 확장 프로그램 설정…’)에서 끌 수 있습니다.

**규칙.** 모든 "원본 → 대상" 조합(확장자, 카테고리 또는 "모두")에 대해 동작을 선택할 수 있습니다.
먼저 묻기, 즉시 변환, 변환하지 않기 — 그리고 원본을 유지할지 여부까지.
가장 구체적인 규칙이 우선 적용되며, 기본값은 비디오는 "묻기", 나머지는 모두 "즉시 변환"입니다.

**확인 패널**은 화면 오른쪽 위에 나타납니다. 이번 변환에 한해 매개변수를 변경하거나
이 확장자 조합에 대한 선택을 기억하도록 할 수 있습니다.

**매개변수:** JPEG/HEIC/AVIF/WebP 품질, 비디오의 경우 코덱(재인코딩 없음 / H.264 / HEVC),
해상도(4K…480p, 업스케일하지 않음), 프레임 레이트, 위치 및 개인 메타데이터 제거,
GIF 프레임 레이트와 너비, AAC/MP3 비트레이트, PDF 페이지 크기.

**업데이트:** "업데이트 확인" 버튼과 [GitHub Releases](https://github.com/Kohinor46/RenameConvert/releases)를
통한 매일 자동 확인. 업데이트는 다운로드된 후 SHA-256과 코드 서명으로 검증되고, 앱을 다시 실행하며 설치됩니다.

**버그 신고:** 메뉴 → "버그 신고…"(또는 오류 알림의 버튼)를 선택하면 개발자에게 보낼 이메일이 작성되며,
여기에 사용자의 설명, 시스템 정보, 앱 로그가 첨부됩니다. 로그:
`~/Library/Logs/RenameConvert/RenameConvert.log`.

**23개 언어:** 영어, 러시아어, 독일어, 프랑스어, 스페인어, 이탈리아어, 포르투갈어(브라질), 네덜란드어, 폴란드어,
우크라이나어, 체코어, 스웨덴어, 튀르키예어, 아랍어, 히브리어, 힌디어, 인도네시아어, 베트남어, 태국어, 일본어, 한국어,
중국어(간체 및 번체).

**그 밖에:** 감시 폴더 및 제외 항목, 메뉴 막대에서의 진행 상황 표시와 취소, "원본 복원"을 지원하는 기록,
원본을 휴지통으로 이동, 알림, 로그인 시 실행. 모든 작업은 로컬에서 처리되며 파일이 Mac 밖으로 나가지 않습니다.

## 빌드

macOS 15 이상과 Command Line Tools(`xcode-select --install`)가 필요합니다. Xcode는 선택 사항이지만,
프로젝트를 Swift 패키지로 Xcode에서 열 수 있습니다(`open Package.swift`).

```bash
./build.sh            # build/RenameConvert.app (유니버설: Apple Silicon + Intel); 첫 실행 시 FFmpeg 빌드 (~15분)
./build.sh install    # ~/Applications에 설치하고 실행
./build.sh dist       # build/RenameConvert.zip (자동 업데이트용) 및 build/RenameConvert.dmg
./build.sh release    # dist + GitHub에 릴리스 v<version> 게시
```

번역: `scripts/extract-strings.py`가 UI 문자열을 `Resources/Localization/keys.json`에 수집합니다.
`--check`는 모든 언어에 모든 문자열이 있고 자리 표시자가 일치하는지 검사합니다.
홍보 영상: `scripts/promo/make-promo.sh`(`say`를 이용한 내레이션, SwiftUI 프레임, FFmpeg로 합성).

## 아키텍처

| 파일 | 역할 |
|---|---|
| `RenameWatcher.swift` | FSEvents: "이전 이름 → 새 이름" 쌍을 감지 |
| `Formats.swift` | 형식 레지스트리: 확장자 쌍을 어떤 엔진이 처리할지 결정 |
| `Rules.swift` | 규칙과 변환 매개변수 |
| `Pipeline.swift` | 작업 폴더, 엔진 실행, 원본을 휴지통으로 이동, 원자적 교체 |
| `Engines/ImageEngine.swift` | 이미지(ImageIO), PDF → 이미지 |
| `Engines/MediaEngine.swift` | 비디오, GIF, 오디오(AVFoundation, afconvert) |
| `Engines/DocumentEngine.swift` | 문서(NSAttributedString, PDFKit, CoreText) |
| `Engines/DataArchiveEngines.swift` | JSON ↔ plist, 아카이브(bsdtar), 공통 오류 |
| `Engines/FFmpegEngine.swift` | 내장 FFmpeg: WebP, MP3, MKV, AVI, WebM, OGG, 팔레트 GIF |
| `Updater.swift` | GitHub Releases에서 업데이트 확인 및 설치 |
| `BugReport.swift`, `Log.swift` | 이메일 버그 신고, 앱 로그 |
| `AppModel.swift` | 설정, 대기열, 확인 요청, 기록, 알림 |
| `AskPanel.swift`, `ParamsForm.swift` | 확인 패널과 매개변수 양식 |
| `RenameConvertApp.swift`, `SettingsView.swift` | 메뉴 막대 메뉴와 설정 윈도우 |
| `FinderExtension/`, `FinderMenu.swift` | Finder 확장 프로그램(‘다음으로 변환’ 하위 메뉴)과 앱에서의 요청 처리 |

## 포함된 구성 요소의 라이선스

FFmpeg는 LGPL 2.1에 따라 별도의 실행 파일(`Contents/Helpers/ffmpeg`)로 포함되어 있으며, LAME(LGPL)과
libwebp(BSD)를 포함하여 빌드되었습니다. 라이선스 전문은 `Contents/Resources/Licenses`에 있으며, 실제 빌드 스크립트는
`scripts/build-ffmpeg.sh`입니다.
