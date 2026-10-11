#!/bin/bash
# Тесты: scripts/test.sh [аргументы swift test, например --filter Pipeline]
# Тесты с ffmpeg берут vendor/ffmpeg/ffmpeg (собирается scripts/build-ffmpeg.sh); без него они пропускаются.
set -euo pipefail
cd "$(dirname "$0")/.."

FLAGS=()
# Только Command Line Tools (без Xcode): Testing.framework лежит вне стандартных путей поиска.
DEV=$(xcode-select -p)
if [[ $DEV == */CommandLineTools ]]; then
  F="$DEV/Library/Developer/Frameworks" L="$DEV/Library/Developer/usr/lib"
  FLAGS=(-Xswiftc -F -Xswiftc "$F" -Xlinker -F -Xlinker "$F" -Xlinker -rpath -Xlinker "$F" -Xlinker -rpath -Xlinker "$L")
fi
swift test "${FLAGS[@]}" "$@"
