#!/bin/bash
# Собирает промо-ролики для Instagram Reels: promo/RenameConvert-promo-<lang>.mp4 (1080×1920, озвучка + субтитры).
# Запуск: FIXTURES=<папка с образцами> scripts/promo/make-promo.sh [ru en]
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
sips -s format png Resources/AppIcon.icns --out "$WORK/icon.png" >/dev/null

for L in $LANGS; do
  # Голоса можно переопределить: VOICE_RU="Milena (Enhanced)" VOICE_EN="Ava (Premium)" (см. say -v "?")
  case $L in ru) VOICE=${VOICE_RU:-Milena}; RATE=180 ;; *) VOICE=${VOICE_EN:-Samantha}; RATE=175 ;; esac
  # Имя файла с голосом: RenameConvert-promo-ru-milena-enhanced.mp4
  SLUG=$(echo "$VOICE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\{1,\}/-/g; s/-$//')
  NAME="RenameConvert-promo-$L-$SLUG"
  rm -rf "$WORK/$L-audio" && mkdir -p "$WORK/$L-audio"
  DURS=() FILTER="" INPUTS=() i=0
  while IFS= read -r line; do
    f="$WORK/$L-audio/$i.aiff"
    say -v "$VOICE" -r "$RATE" -o "$f" "$line"
    d=$(afinfo "$f" | awk '/estimated duration/ {print $3}')
    # Сцена = 0.3 с паузы + реплика + 0.6 с паузы
    sd=$(python3 -c "print(round($d + 0.9, 2))")
    DURS+=("$sd")
    INPUTS+=(-i "$f")
    FILTER+="[$i:a]aresample=48000,aformat=channel_layouts=stereo,adelay=300|300,apad=whole_dur=$sd[a$i];"
    i=$((i + 1))
  done < <("$WORK/promo" lines "$L")

  CONCAT=$(for ((j = 0; j < i; j++)); do printf "[a%d]" $j; done)
  printf '[%s]\n' "$(IFS=,; echo "${DURS[*]}")" > "$WORK/$L-durations.json"
  "$FF" -hide_banner -loglevel error -y "${INPUTS[@]}" -filter_complex "${FILTER}${CONCAT}concat=n=$i:v=0:a=1[out]" \
    -map "[out]" -c:a aac_at -b:a 192k "$WORK/$L-voice.m4a"

  "$WORK/promo" "$L" "$WORK/shots" "$WORK/$L-durations.json" "$WORK/$L-video.mp4" "$WORK/icon.png"
  "$FF" -hide_banner -loglevel error -y -i "$WORK/$L-video.mp4" -i "$WORK/$L-voice.m4a" \
    -map 0:v -map 1:a -c:v copy -c:a copy -shortest -movflags +faststart "$OUT/$NAME.mp4"
  echo "$OUT/$NAME.mp4 ($(du -h "$OUT/$NAME.mp4" | cut -f1))"
done
