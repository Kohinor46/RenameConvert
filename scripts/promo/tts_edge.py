#!/usr/bin/env python3
"""Озвучивает весь сценарий одним куском нейроголосом Microsoft (edge-tts) и сообщает,
когда в получившемся звуке начинается и заканчивается каждая фраза.

  tts_edge.py <phrases.json> <голос> <темп, напр. +5%> <out.mp3> <timings.json> [<ffmpeg> <out.wav>]

phrases.json — список фраз (уже в «произносимом» виде). timings.json — [[начало, конец], …] в секундах.
Озвучка одним куском даёт естественную речь без пауз-склеек; время фраз берётся из меток слов (WordBoundary).
Если указан ffmpeg — паузы между предложениями (у синтезатора ~0.85 с) сжимаются до ~0.15 с: результат в out.wav,
а timings.json пересчитывается под него.
"""
import asyncio
import json
import os
import subprocess
import sys

import edge_tts

# Сколько тишины оставить до и после фразы (сек); можно задать через окружение.
PAUSE_BEFORE = float(os.environ.get("PAUSE_BEFORE", "0.05"))
PAUSE_AFTER = float(os.environ.get("PAUSE_AFTER", "0.10"))


def tighten(ffmpeg, src, dst, timings):
    """Оставляет каждую фразу с короткими полями тишины и склеивает подряд."""
    keep, new, cursor = [], [], 0.0
    for start, end in timings:
        a, b = max(0.0, start - PAUSE_BEFORE), end + PAUSE_AFTER
        keep.append(f"between(t,{a:.3f},{b:.3f})")
        new.append([round(cursor + (start - a), 3), round(cursor + (end - a), 3)])
        cursor += b - a
    expr = "+".join(keep)
    subprocess.run([ffmpeg, "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-i", src,
                    "-af", f"aselect='{expr}',asetpts=N/SR/TB", "-ar", "48000", "-ac", "2", dst], check=True)
    return new


async def synthesize(text, voice, rate, out_audio):
    """Синтез с метками слов: [(символ в тексте, начало сек, конец сек)]."""
    words, search = [], 0
    communicate = edge_tts.Communicate(text, voice, rate=rate, boundary="WordBoundary")
    with open(out_audio, "wb") as audio:
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio.write(chunk["data"])
            elif chunk["type"] == "WordBoundary":
                word = chunk["text"]
                at = text.find(word, search)
                if at < 0:          # слово синтезатор записал иначе — ставим на текущую позицию
                    at = search
                else:
                    search = at + len(word)
                begin = chunk["offset"] / 1e7
                words.append((at, begin, begin + chunk["duration"] / 1e7))
    return words


async def main(phrases_path, voice, rate, out_audio, out_timings, ffmpeg=None, out_wav=None):
    phrases = json.load(open(phrases_path, encoding="utf-8"))
    text = " ".join(phrases)
    # Где в общем тексте начинается и кончается каждая фраза (в символах).
    ranges, pos = [], 0
    for p in phrases:
        start = text.index(p, pos)
        ranges.append((start, start + len(p)))
        pos = start + len(p)

    # Сервис иногда не отдаёт звук (NoAudioReceived) — повторяем с паузой.
    for attempt in range(5):
        try:
            words = await synthesize(text, voice, rate, out_audio)
            break
        except edge_tts.exceptions.NoAudioReceived:
            if attempt == 4:
                raise
            await asyncio.sleep(2 + 2 * attempt)

    timings = []
    for a, b in ranges:
        inside = [w for w in words if a <= w[0] < b]
        if not inside:
            raise SystemExit(f"нет меток слов для фразы: {text[a:b]!r}")
        timings.append([round(inside[0][1], 3), round(inside[-1][2], 3)])
    if ffmpeg and out_wav:
        timings = tighten(ffmpeg, out_audio, out_wav, timings)
    json.dump(timings, open(out_timings, "w"))


if __name__ == "__main__":
    asyncio.run(main(*sys.argv[1:8]))
