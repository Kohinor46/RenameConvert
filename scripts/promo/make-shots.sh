#!/bin/bash
# Снимает скриншоты окон на указанных языках: scripts/promo/make-shots.sh <out> ru en de …
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); shift
WORK=$(cd "$(mktemp -d)" && pwd -P)   # реальный путь: события FSEvents приходят без ссылок
APP="$WORK/Shots.app"
# Домашняя папка подменяется, чтобы в окнах был путь ~/Desktop, а не временная папка.
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$WORK/home/Desktop"
FILES="$WORK/home/Desktop"

swiftc -O -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macos15.0" \
  $(ls Sources/RenameConvert/*.swift Sources/RenameConvert/Engines/*.swift | grep -v RenameConvertApp.swift) \
  scripts/promo/Shots.swift -o "$APP/Contents/MacOS/shots"
cp -R Resources/Localization/*.lproj "$APP/Contents/Resources/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.renameconvert.shots</string>
<key>CFBundleExecutable</key><string>shots</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>RCUpdateRepository</key><string>Kohinor46/RenameConvert</string>
</dict></plist>
EOF
codesign --force --sign - "$APP" 2>/dev/null

# Файлы для миниатюр в истории и для окна-вопроса.
FIX=${FIXTURES:?укажите FIXTURES — папку с clip.mov, a.jpg, clip.gif, doc.pdf}
cp "$FIX/a.jpg" "$FILES/vacation.jpg"
cp "$FIX/clip.gif" "$FILES/clip.gif"
cp "$FIX/doc.pdf" "$FILES/report.pdf"
cp "$FIX/speech.mp3" "$FILES/interview.mp3" 2>/dev/null || true

for L in "$@"; do
  cp "$FIX/clip.mov" "$FILES/holiday.mov"
  rm -f "$FILES/holiday.mp4"
  HOME="$WORK/home" CFFIXED_USER_HOME="$WORK/home" "$APP/Contents/MacOS/shots" "$FILES" "$OUT/$L" -AppleLanguages "($L)" 2>&1 | grep -v attributedString || true
  echo "$L: $(ls "$OUT/$L" | wc -l | tr -d ' ') снимков"
done
rm -rf "$WORK"
