#!/bin/bash
# ./build.sh            — собрать build/RenameConvert.app
# ./build.sh install    — собрать, установить в ~/Applications и запустить
# ./build.sh dist       — собрать build/RenameConvert.zip (для обновлений) и build/RenameConvert.dmg
# ./build.sh release    — dist + опубликовать релиз v<версия> на GitHub (нужен gh)
set -euo pipefail
cd "$(dirname "$0")"

APP=build/RenameConvert.app
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
REPO=$(/usr/libexec/PlistBuddy -c "Print RCUpdateRepository" Resources/Info.plist)

# Универсальный бинарник (Apple Silicon + Intel): собираем обе архитектуры и склеиваем.
BINS=() EXT_BINS=()
for ARCH in arm64 x86_64; do
  TRIPLE="$ARCH-apple-macosx15.0"
  swift build -c release --triple "$TRIPLE"
  BINS+=("$(swift build -c release --triple "$TRIPLE" --show-bin-path)/RenameConvert")
  # Расширение Finder (контекстное меню). SwiftPM не собирает .appex — компилируем напрямую;
  # Formats.swift общий с приложением.
  swiftc -O -swift-version 5 -target "$TRIPLE" -module-name RenameConvertFinder -application-extension \
    -parse-as-library -Xlinker -e -Xlinker _NSExtensionMain \
    FinderExtension/*.swift Sources/RenameConvert/Formats.swift -o ".build/RenameConvertFinder-$ARCH"
  EXT_BINS+=(".build/RenameConvertFinder-$ARCH")
done
BIN=.build/RenameConvert-universal
lipo -create "${BINS[@]}" -output "$BIN"

[[ -f Resources/AppIcon.icns ]] || swift scripts/make-icon.swift Resources/AppIcon.icns
[[ -x vendor/ffmpeg/ffmpeg ]] || scripts/build-ffmpeg.sh

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources/Licenses"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp "$BIN" "$APP/Contents/MacOS/RenameConvert"
cp vendor/ffmpeg/ffmpeg "$APP/Contents/Helpers/ffmpeg"

APPEX="$APP/Contents/PlugIns/RenameConvertFinder.appex"
mkdir -p "$APPEX/Contents/MacOS" "$APPEX/Contents/Resources"
lipo -create "${EXT_BINS[@]}" -output "$APPEX/Contents/MacOS/RenameConvertFinder"
cp FinderExtension/Info.plist "$APPEX/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
  -c "Set :CFBundleVersion $(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Resources/Info.plist)" "$APPEX/Contents/Info.plist"

# Переводы. Русский — язык разработки: ключи и есть русские строки (ru.lproj: ключ = значение).
cp -R Resources/Localization/*.lproj "$APP/Contents/Resources/"

LANGS=$(cd Resources/Localization && ls -d *.lproj | sed 's/\.lproj$//' | tr '\n' ' ')
/usr/libexec/PlistBuddy -c "Delete :CFBundleLocalizations" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations array" "$APP/Contents/Info.plist"
for L in $LANGS; do /usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations: string $L" "$APP/Contents/Info.plist"; done
for L in $LANGS; do
  mkdir -p "$APPEX/Contents/Resources/$L.lproj"
  cp "Resources/Localization/$L.lproj/Localizable.strings" "$APPEX/Contents/Resources/$L.lproj/"
done

# Лицензии компонентов (FFmpeg — LGPL 2.1: исходники и скрипт сборки — scripts/build-ffmpeg.sh).
cp vendor/ffmpeg/LICENSE-*.txt "$APP/Contents/Resources/Licenses/"
cat > "$APP/Contents/Resources/Licenses/README.txt" <<EOF
RenameConvert includes FFmpeg (https://ffmpeg.org), licensed under LGPL 2.1,
built with LAME (LGPL) and libwebp (BSD). FFmpeg is a separate executable in
Contents/Helpers/ffmpeg. Source code and the exact build script:
https://github.com/$REPO/blob/main/scripts/build-ffmpeg.sh
EOF

# Сначала подписываем вложенное (ffmpeg, расширение — оно обязано быть в песочнице), потом приложение.
codesign --force --options runtime --sign - "$APP/Contents/Helpers/ffmpeg"
codesign --force --options runtime --sign - --entitlements FinderExtension/FinderSync.entitlements "$APPEX"
codesign --force --options runtime --sign - "$APP"
echo "Собрано: $APP $VERSION ($(lipo -archs "$APP/Contents/MacOS/RenameConvert"), $(du -sh "$APP" | cut -f1))"

dist() {
  rm -f build/RenameConvert.zip build/RenameConvert.dmg
  ditto -c -k --keepParent "$APP" build/RenameConvert.zip
  STAGE=build/dmg
  rm -rf "$STAGE" && mkdir -p "$STAGE"
  cp -R "$APP" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create -volname RenameConvert -srcfolder "$STAGE" -ov -format UDZO build/RenameConvert.dmg >/dev/null 2>&1
  rm -rf "$STAGE"
  echo "Архивы: build/RenameConvert.zip, build/RenameConvert.dmg"
}

case "${1:-}" in
  install)
    pkill -x RenameConvert 2>/dev/null && sleep 0.5 || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/RenameConvert.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/RenameConvert.app
    echo "Установлено и запущено: ~/Applications/RenameConvert.app"
    ;;
  dist)
    dist
    ;;
  release)
    dist
    # Заметки из NOTES_FILE, иначе — сгенерированные GitHub.
    NOTES=(--generate-notes)
    [[ -n ${NOTES_FILE:-} ]] && NOTES=(--notes-file "$NOTES_FILE")
    gh release create "v$VERSION" build/RenameConvert.zip build/RenameConvert.dmg \
      --repo "$REPO" --title "RenameConvert $VERSION" "${NOTES[@]}"
    ;;
esac
