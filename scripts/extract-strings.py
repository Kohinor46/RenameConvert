#!/usr/bin/env python3
"""Собирает из исходников все строки интерфейса (на русском — это язык разработки) и
проверяет переводы.

  scripts/extract-strings.py            — пишет Resources/Localization/keys.json
  scripts/extract-strings.py --check    — проверяет, что во всех *.lproj есть все ключи
                                          и совпадают подстановки (%@, %lld)
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Sources" / "RenameConvert"
LOCALIZATION = ROOT / "Resources" / "Localization"
CYRILLIC = re.compile(r"[А-Яа-яЁё]")
SPEC = re.compile(r"%(?:lld|@|%)")


def literals(text):
    """Строковые литералы Swift (без многострочных) с разбором \\( ... ) и escape-последовательностей."""
    i, n = 0, len(text)
    while i < n:
        if text.startswith('"""', i):
            end = text.find('"""', i + 3)
            i = n if end < 0 else end + 3
            continue
        if text.startswith("//", i):
            i = text.find("\n", i)
            i = n if i < 0 else i
            continue
        if text[i] != '"':
            i += 1
            continue
        i += 1
        out = []
        while i < n and text[i] != '"':
            c = text[i]
            if c == "\\" and i + 1 < n:
                nxt = text[i + 1]
                if nxt == "(":
                    depth, j = 1, i + 2
                    while j < n and depth:
                        if text[j] == "(":
                            depth += 1
                        elif text[j] == ")":
                            depth -= 1
                        elif text[j] == '"':  # литерал внутри подстановки
                            j = text.find('"', j + 1)
                        j += 1
                    expr = text[i + 2:j - 1].strip()
                    out.append(("expr", expr))
                    i = j
                    continue
                out.append(("char", {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(nxt, nxt)))
                i += 2
                continue
            out.append(("char", c))
            i += 1
        i += 1
        line_start = text.rfind("\n", 0, i) + 1
        yield out, text[line_start:text.find("\n", i)]


def to_key(parts):
    key = []
    for kind, value in parts:
        if kind == "char":
            key.append("%%" if value == "%" else value)
        # Целые числа: $0 из ForEach по Int, …count / …Count, Int(…) → %lld; всё остальное → %@
        elif value == "$0" or re.search(r"(^|\.)count\b|Count\b", value) or value.startswith("Int("):
            key.append("%lld")
        else:
            key.append("%@")
    return "".join(key)


def extract():
    keys = []
    for path in sorted(SOURCES.rglob("*.swift")):
        if path.name == "Languages.swift":   # самоназвания языков не переводятся
            continue
        for parts, line in literals(path.read_text()):
            raw = "".join(v for k, v in parts if k == "char")
            if not CYRILLIC.search(raw) or "Log.info(" in line or "Log.error(" in line:
                continue
            key = to_key(parts)
            if key not in keys:
                keys.append(key)
    return keys


def parse_strings(path):
    text = path.read_text(encoding="utf-8")
    pairs = re.findall(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";', text, re.M)
    unescape = lambda s: s.replace('\\n', '\n').replace('\\"', '"').replace('\\\\', '\\')
    return {unescape(k): unescape(v) for k, v in pairs}


def check():
    keys = json.loads((LOCALIZATION / "keys.json").read_text())
    ok = True
    for lproj in sorted(LOCALIZATION.glob("*.lproj")):
        strings = lproj / "Localizable.strings"
        if lproj.name == "ru.lproj":
            continue
        if not strings.exists():
            print(f"{lproj.name}: нет Localizable.strings"); ok = False; continue
        table = parse_strings(strings)
        missing = [k for k in keys if k not in table]
        bad = [k for k in keys if k in table and sorted(SPEC.findall(k)) != sorted(SPEC.findall(table[k]))]
        if missing or bad:
            ok = False
            print(f"{lproj.name}: нет {len(missing)}, неверные подстановки {len(bad)}")
            for k in (missing + bad)[:5]:
                print("   ", repr(k))
        else:
            print(f"{lproj.name}: OK ({len(table)})")
    return ok


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(0 if check() else 1)
    keys = extract()
    LOCALIZATION.mkdir(parents=True, exist_ok=True)
    (LOCALIZATION / "keys.json").write_text(json.dumps(keys, ensure_ascii=False, indent=1) + "\n")
    # Русский — язык разработки: ключ = значение. Файл нужен, чтобы macOS считала русский доступным языком.
    ru = LOCALIZATION / "ru.lproj"
    ru.mkdir(exist_ok=True)
    esc = lambda s: s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    (ru / "Localizable.strings").write_text("".join(f'"{esc(k)}" = "{esc(k)}";\n' for k in keys), encoding="utf-8")
    print(f"{len(keys)} строк → {LOCALIZATION / 'keys.json'}")
