#!/usr/bin/env python3
"""Вставляет строку выбора языка между <!-- languages --> и <!-- /languages --> во все README
(README.md — английский, docs/README.<lang>.md — остальные) и проверяет, что структура переводов совпадает."""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGUAGES = [
    ("en", "English"), ("ru", "Русский"), ("de", "Deutsch"), ("fr", "Français"), ("es", "Español"),
    ("it", "Italiano"), ("pt-BR", "Português (Brasil)"), ("nl", "Nederlands"), ("pl", "Polski"),
    ("uk", "Українська"), ("cs", "Čeština"), ("sv", "Svenska"), ("tr", "Türkçe"), ("ar", "العربية"),
    ("he", "עברית"), ("hi", "हिन्दी"), ("id", "Bahasa Indonesia"), ("vi", "Tiếng Việt"), ("th", "ไทย"),
    ("ja", "日本語"), ("ko", "한국어"), ("zh-Hans", "简体中文"), ("zh-Hant", "繁體中文"),
]


def path_for(code):
    return ROOT / "README.md" if code == "en" else ROOT / "docs" / f"README.{code}.md"


def bar(current):
    in_docs = current != "en"
    items = []
    for code, name in LANGUAGES:
        if code == current:
            items.append(f"**{name}**")
            continue
        if code == "en":
            link = "../README.md" if in_docs else "README.md"
        else:
            link = f"README.{code}.md" if in_docs else f"docs/README.{code}.md"
        items.append(f"[{name}]({link})")
    return "🌐 " + " · ".join(items)


def shape(text):
    return (len(re.findall(r"^## ", text, re.M)), len(re.findall(r"^\s*\|", text, re.M)))


english = shape(path_for("en").read_text(encoding="utf-8"))
ok = True
for code, _ in LANGUAGES:
    path = path_for(code)
    if not path.exists():
        print(f"{code}: нет файла {path.relative_to(ROOT)}")
        ok = False
        continue
    text = path.read_text(encoding="utf-8")
    new, n = re.subn(r"<!-- languages -->.*?<!-- /languages -->",
                     f"<!-- languages -->\n{bar(code)}\n<!-- /languages -->", text, count=1, flags=re.S)
    if n == 0:
        print(f"{code}: нет маркеров <!-- languages -->")
        ok = False
        continue
    path.write_text(new, encoding="utf-8")
    if shape(new) != english:
        print(f"{code}: структура отличается {shape(new)} ≠ {english}")
        ok = False
print("OK" if ok else "Есть проблемы")
