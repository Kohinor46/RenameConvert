#!/bin/bash
# Собирает статический универсальный (arm64 + x86_64) ffmpeg под LGPL с поддержкой MP3 (LAME) и WebP (libwebp).
# Результат: vendor/ffmpeg/ffmpeg. Зависит только от системных фреймворков macOS.
# Запуск: scripts/build-ffmpeg.sh   (повторный запуск пропускает уже собранное)
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD/vendor"
SRC="$ROOT/src"
OUT="$ROOT/ffmpeg/ffmpeg"
JOBS=$(sysctl -n hw.ncpu)
MIN_MACOS=13.0

FFMPEG_VER=7.1.1
LAME_VER=3.100
WEBP_VER=1.5.0

if [[ -x "$OUT" ]]; then echo "Уже собрано: $OUT"; exit 0; fi

fetch() {  # fetch <имя> <url> <sha256>: каждый архив — в собственную пустую папку, с проверкой суммы
  local name=$1 url=$2 sha=$3 dir="$SRC/$1"
  [[ -d "$dir/src" ]] && return
  rm -rf "$dir" && mkdir -p "$dir/src"
  echo "Скачиваю $url"
  curl -fL --retry 3 -o "$dir/archive" "$url"
  echo "$sha  $dir/archive" | shasum -a 256 -c -
  tar -xf "$dir/archive" -C "$dir/src" --strip-components 1
}

fetch ffmpeg "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.xz" \
  733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1
fetch lame "https://downloads.sourceforge.net/project/lame/lame/$LAME_VER/lame-$LAME_VER.tar.gz" \
  ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
fetch libwebp "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$WEBP_VER.tar.gz" \
  7d6fab70cf844bf6769077bd5d7a74893f8ffd4dfb42861745750c63c2a5c92c

build_arch() {
  local arch=$1
  local prefix="$ROOT/build/$arch"
  local host; [[ $arch == arm64 ]] && host=aarch64-apple-darwin || host=x86_64-apple-darwin
  local cflags="-arch $arch -mmacosx-version-min=$MIN_MACOS -O2"
  [[ -x "$prefix/bin/ffmpeg" ]] && return
  mkdir -p "$prefix"

  echo "== LAME ($arch)"
  rm -rf "$ROOT/build/lame-$arch" && cp -R "$SRC/lame/src" "$ROOT/build/lame-$arch"
  (cd "$ROOT/build/lame-$arch" &&
    # В lame 3.100 в списке экспорта есть символ, которого нет в сборке, — убираем его.
    sed -i '' '/lame_init_old/d' include/libmp3lame.sym &&
    CFLAGS="$cflags" ./configure --host="$host" --prefix="$prefix" --disable-shared --enable-static \
      --disable-frontend --disable-decoder --disable-dependency-tracking >/dev/null &&
    make -j"$JOBS" >/dev/null && make install >/dev/null)

  echo "== libwebp ($arch)"
  rm -rf "$ROOT/build/webp-$arch" && cp -R "$SRC/libwebp/src" "$ROOT/build/webp-$arch"
  (cd "$ROOT/build/webp-$arch" &&
    CFLAGS="$cflags" ./configure --host="$host" --prefix="$prefix" --disable-shared --enable-static \
      --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic \
      --disable-dependency-tracking >/dev/null &&
    make -j"$JOBS" >/dev/null && make install >/dev/null)

  echo "== ffmpeg ($arch)"
  rm -rf "$ROOT/build/ffmpeg-$arch" && mkdir -p "$ROOT/build/ffmpeg-$arch"
  local extra=()
  [[ $arch != "$(uname -m)" ]] && extra+=(--enable-cross-compile)
  [[ $arch == x86_64 ]] && extra+=(--disable-x86asm)   # nasm не нужен; на Intel чуть медленнее
  (cd "$ROOT/build/ffmpeg-$arch" &&
    PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig" PKG_CONFIG_PATH="" \
    "$SRC/ffmpeg/src/configure" --prefix="$prefix" --arch="$arch" --target-os=darwin \
      --cc="clang -arch $arch" --extra-cflags="-I$prefix/include -mmacosx-version-min=$MIN_MACOS" \
      --extra-ldflags="-L$prefix/lib -mmacosx-version-min=$MIN_MACOS" --extra-libs="-liconv" --pkg-config-flags=--static \
      --disable-autodetect --disable-debug --disable-doc --disable-ffplay --disable-ffprobe \
      --disable-network --enable-static --disable-shared \
      --enable-videotoolbox --enable-audiotoolbox --enable-zlib --enable-bzlib --enable-iconv \
      --enable-libmp3lame --enable-libwebp ${extra[@]+"${extra[@]}"} >/dev/null &&
    make -j"$JOBS" >/dev/null && make install >/dev/null)
}

build_arch arm64
build_arch x86_64

mkdir -p "$(dirname "$OUT")"
lipo -create "$ROOT/build/arm64/bin/ffmpeg" "$ROOT/build/x86_64/bin/ffmpeg" -output "$OUT"
strip -x "$OUT"
cp "$SRC/ffmpeg/src/COPYING.LGPLv2.1" "$ROOT/ffmpeg/LICENSE-ffmpeg.txt"
cp "$SRC/lame/src/COPYING" "$ROOT/ffmpeg/LICENSE-lame.txt"
cp "$SRC/libwebp/src/COPYING" "$ROOT/ffmpeg/LICENSE-libwebp.txt"
echo "Готово: $OUT ($(lipo -archs "$OUT"), $(du -h "$OUT" | cut -f1))"
otool -L "$OUT"
