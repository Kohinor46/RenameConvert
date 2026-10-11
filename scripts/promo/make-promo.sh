#!/bin/bash
# Собирает промо-ролики для Instagram Reels: promo/RenameConvert-promo-<lang>-<голос>.mp4 (1080×1920).
# Запуск: FIXTURES=<папка с образцами> scripts/promo/make-promo.sh [ru en]
# Голоса: VOICE_RU="Milena (Enhanced)" VOICE_EN="Serena (Premium)" (список — say -v "?"); темп — RATE_RU / RATE_EN.
set -euo pipefail
cd "$(dirname "$0")/../.."
LANGS=${*:-ru en}
FF=vendor/ffmpeg/ffmpeg
WORK=build/promo
OUT=promo
mkdir -p "$WORK" "$OUT"

# Пересобираем рендер и переснимаем окна, только если нужно.
[[ "$WORK/promo" -nt scripts/promo/Promo.swift ]] || \
  swiftc -O -parse-as-library -target "$(uname -m)-apple-macos15.0" scripts/promo/Promo.swift -o "$WORK/promo"
for L in $LANGS; do [[ -f "$WORK/shots/$L/rules.png" ]] || scripts/promo/make-shots.sh "$WORK/shots" "$L"; done
[[ -f "$WORK/icon.png" ]] || sips -s format png Resources/AppIcon.icns --out "$WORK/icon.png" >/dev/null

# Звуковые эффекты (синтезированы, без чужих сэмплов): «вжух» для переходов и щелчок мыши.
"$FF" -nostdin -hide_banner -loglevel error -y -f lavfi -i "anoisesrc=d=0.4:c=pink:a=0.6" \
  -af "highpass=f=300,lowpass=f=5000,afade=t=in:d=0.22:curve=exp,afade=t=out:st=0.22:d=0.18,volume=0.12" \
  -ar 48000 -ac 2 "$WORK/whoosh.wav"
"$FF" -nostdin -hide_banner -loglevel error -y -f lavfi -i "anoisesrc=d=0.03:c=white:a=0.8" \
  -af "highpass=f=1800,afade=t=out:st=0.004:d=0.026,volume=0.5" -ar 48000 -ac 2 "$WORK/click.wav"

for L in $LANGS; do
  case $L in
    ru) VOICE=${VOICE_RU:-Milena}; RATE=${RATE_RU:-200} ;;
    *)  VOICE=${VOICE_EN:-Samantha}; RATE=${RATE_EN:-192} ;;
  esac
  # Имя файла с голосом: RenameConvert-promo-ru-milena-enhanced.mp4
  SLUG=$(echo "$VOICE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\{1,\}/-/g; s/-$//')
  NAME="RenameConvert-promo-$L-$SLUG"
  AUDIO="$WORK/$L-$SLUG"
  rm -rf "$AUDIO" && mkdir -p "$AUDIO"

  # Каждая фраза — отдельный файл: так анимация и субтитры точно попадают в речь.
  DURS=() i=0
  while IFS=$'\t' read -r _scene text; do
    say -v "$VOICE" -r "$RATE" -o "$AUDIO/$i.aiff" "$text"
    DURS+=("$(afinfo "$AUDIO/$i.aiff" | awk '/estimated duration/ {print $3}')")
    i=$((i + 1))
  done < <("$WORK/promo" lines "$L")
  printf '[%s]\n' "$(IFS=,; echo "${DURS[*]}")" > "$AUDIO/durations.json"

  "$WORK/promo" render "$L" "$WORK/shots" "$AUDIO/durations.json" "$AUDIO/video.mp4" "$WORK/icon.png"

  # Звуковая дорожка по плану рендера: голос, переходы, щелчки.
  "$WORK/promo" mix "$AUDIO/video.mp4.plan" "$AUDIO" "$WORK/whoosh.wav" "$WORK/click.wav" "$AUDIO/audio.wav"
  "$FF" -nostdin -hide_banner -loglevel error -y -i "$AUDIO/audio.wav" -c:a aac_at -b:a 192k "$AUDIO/audio.m4a"
  TOTAL=$(awk '/^total/ {printf "%.1f", $2/1000}' "$AUDIO/video.mp4.plan")

  "$FF" -nostdin -hide_banner -loglevel error -y -i "$AUDIO/video.mp4" -i "$AUDIO/audio.m4a" \
    -map 0:v -map 1:a -c:v copy -c:a copy -shortest -movflags +faststart "$OUT/$NAME.mp4"
  echo "$OUT/$NAME.mp4 ($(du -h "$OUT/$NAME.mp4" | cut -f1), ${TOTAL} с)"
done
