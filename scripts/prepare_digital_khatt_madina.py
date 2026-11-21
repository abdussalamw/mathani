"""Prepare the single-font trial: DigitalKhatt Unicode text in Mathani's QCF4 lines.

Input: ClientApp/src/app/services/quran_text_madina.ts from
https://github.com/DigitalKhatt/digitalkhatt.org/tree/4213fab9892774f74f7164c70a70dd84a14f0215
Font: https://github.com/DigitalKhatt/madinafont/tree/9aeb02c26d8dae4c032820733466c1ee9137e6d6
Run from the project root: python scripts/prepare_digital_khatt_madina.py <input.ts>
"""

import ast
from collections import Counter, defaultdict, deque
import hashlib
import json
from pathlib import Path
import re
import sys
from zipfile import ZipFile


def require(condition, message):
    if not condition:
        raise ValueError(message)


def build(source):
    raw = source.read_bytes()
    require(hashlib.sha256(raw).hexdigest() ==
            "555b4bbb9052e60165988a8c39784871c2235adbe0c83c69f450c85ad1633997",
            "Revalidate the text and its encoding before updating the source revision.")
    text = raw.decode("utf-8-sig")
    pages = ast.literal_eval(text[text.index("["):text.rindex("]") + 1])
    words = defaultdict(deque)
    titles, basmalas, endings = {}, {}, {}
    surah, ayah = 0, 1
    for page in pages:
        for line in page:
            if line.startswith("سُورَةُ "):
                surah, ayah = surah + 1, 1
                titles[surah] = line
            elif line == "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ":
                basmalas[surah] = line
            else:
                for token in line.split():
                    key = (surah, ayah)
                    if re.fullmatch("۝[٠-٩]+", token):
                        require(int(token[1:]) == ayah, f"Unexpected verse number at {key}")
                        endings[key] = token
                        ayah += 1
                    else:
                        words[key].append(token)

    with ZipFile("sorse/quran_fonts_qfc4.zip") as archive:
        layout = json.loads(archive.read("quran_glyphs.json"))
        alignment = json.loads(archive.read("qcf4_line_alignment.json"))
    require(len(layout) == len(pages) == 604 and len(endings) == 6236,
            "Incomplete Quran reference")
    output = []
    counts = Counter()
    reference_marks, text_marks = Counter(), Counter()
    word_number = 0
    for p, page in enumerate(layout, 1):
        require(page["page"] == p, f"Unexpected page {p}")
        lines = []
        for n, line in enumerate(page["lines"], 1):
            require(line["line"] == n, f"Unexpected line {p}/{n}")
            runs = []
            for glyph in line["glyphs"]:
                kind, s, a = glyph["type"], glyph["surah"], glyph.get("ayah", 0)
                key = (s, a)
                if kind == 1:
                    token = words[key].popleft()
                    word_number += 1
                    # U+06DC inside a word can be a small seen. At the end
                    # (possibly before another pause mark) it denotes sakt.
                    for _ in re.finditer(r"[ۖ-ۛ]|ۜ(?=[ۖ-ۛ]|$)", token):
                        text_marks[word_number, 3] += 1
                    if "۞" in token:
                        text_marks[word_number, 4] += 1
                    if "۩" in token:
                        text_marks[word_number, 5] += 1
                elif kind == 2:
                    require(not words[key], f"Remaining words at verse ending {key}")
                    token = endings.pop(key)
                elif kind == 6:
                    token = titles.pop(s)
                elif kind == 8:
                    token = basmalas.pop(s)
                elif kind in (3, 4, 5):
                    # A rub precedes its word. Stops and sajdahs follow it.
                    reference_marks[word_number + int(kind == 4), kind] += 1
                    continue
                else:
                    raise ValueError(f"Unknown glyph type {kind}")
                counts[kind] += 1
                if runs and runs[-1][:2] == [s, a]:
                    runs[-1][2] += " " + token
                else:
                    runs.append([s, a, token])
            require(runs, f"Empty line {p}/{n}")
            centered = p <= 2 or alignment[str(p)][str(n)]["c"] == 1
            lines.append([centered, runs])
        require(len(lines) == (8 if p <= 2 else 15), f"Invalid page length {p}")
        output.append(lines)
    require(not any(words.values()) and not endings and not titles and not basmalas,
            "Unmatched input text")
    require(counts == {1: 77433, 2: 6236, 6: 114, 8: 112}, f"Unexpected totals: {counts}")
    require(text_marks == reference_marks, "Stop, rub or sajdah position differs from QCF4")
    return output


if __name__ == "__main__":
    data = build(Path(sys.argv[1]))
    Path("assets/data/digital_khatt_1441.json").write_bytes(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    )
