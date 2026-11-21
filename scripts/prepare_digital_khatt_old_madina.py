"""Prepare the single-font Old Madina 1995 dataset: DigitalKhatt Unicode text in Mathani's QPC V1 lines.

Input: .dart_tool/old_madina_font_review/quran_text_old_madinah.ts
Layout: sorse/الطبعة القديمة 1405/New folder/qpc_v1_layout.json
Alignment: assets/data/qpc_v1_line_alignment.json
Font: assets/fonts/digital_khatt/oldmadina.otf

Run from the project root: python scripts/prepare_digital_khatt_old_madina.py
"""

import ast
from collections import Counter
import json
from pathlib import Path
import re
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def build(ts_path, layout_path, alignment_path, output_path):
    raw_text = Path(ts_path).read_text(encoding="utf-8")
    start = raw_text.index("[")
    end = raw_text.rindex("]")
    pages_ts = ast.literal_eval(raw_text[start : end + 1])

    layout = json.loads(Path(layout_path).read_text(encoding="utf-8"))
    alignment = json.loads(Path(alignment_path).read_text(encoding="utf-8"))

    require(
        len(pages_ts) == 604 and len(layout) == 604 and len(alignment) == 604,
        "Incomplete 604-page Quran reference",
    )

    arabic_digits = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")
    output_pages = []
    total_ayah_endings = 0
    total_surah_headers = 0
    total_basmalas = 0

    for p in range(1, 605):
        p_str = str(p)
        lines_ts = pages_ts[p - 1]
        lines_lay = layout[p_str]
        require(
            len(lines_ts) == len(lines_lay),
            f"Page {p} line count mismatch: ts={len(lines_ts)} lay={len(lines_lay)}",
        )

        page_lines = []
        for line_idx, (ts_line, lay_line) in enumerate(zip(lines_ts, lines_lay), 1):
            line_align = alignment[p_str][str(line_idx)]
            centered = p <= 2 or line_align["c"] == 1

            has_t6 = any(g.get("t") == 6 for g in lay_line)
            has_t8 = any(g.get("t") == 8 for g in lay_line)

            if has_t6:
                s = next(g["s"] for g in lay_line if g.get("t") == 6)
                page_lines.append([True, [[s, 0, ts_line]]])
                total_surah_headers += 1
            elif has_t8:
                # Basmala: identify surah from header above or verse line below
                s = None
                if line_idx > 1 and any(g.get("t") == 6 for g in lines_lay[line_idx - 2]):
                    s = next(g["s"] for g in lines_lay[line_idx - 2] if g.get("t") == 6)
                elif line_idx < len(lines_lay):
                    s = next((g["s"] for g in lines_lay[line_idx] if "s" in g), None)
                page_lines.append([True, [[s or 0, 0, ts_line]]])
                total_basmalas += 1
            else:
                # Verse line
                ts_line = re.sub(r"۩(?=۝)", "۩ ", ts_line)
                lay_sa_list = []
                for g in lay_line:
                    sa = (g["s"], g["a"])
                    if not lay_sa_list or lay_sa_list[-1] != sa:
                        lay_sa_list.append(sa)

                tokens = ts_line.split()
                runs = []
                curr_sa_idx = 0
                curr_tokens = []

                for token in tokens:
                    curr_tokens.append(token)
                    match = re.search(r"۝([٠-٩]+)", token)
                    if match:
                        end_ayah = int(match.group(1).translate(arabic_digits))
                        require(
                            curr_sa_idx < len(lay_sa_list),
                            f"P{p}:L{line_idx} unexpected ayah ending {end_ayah}",
                        )
                        expected_s, expected_a = lay_sa_list[curr_sa_idx]
                        require(
                            end_ayah == expected_a,
                            f"P{p}:L{line_idx} ayah mismatch: got {end_ayah}, expected {expected_a}",
                        )
                        runs.append([expected_s, expected_a, " ".join(curr_tokens)])
                        curr_tokens = []
                        curr_sa_idx += 1
                        total_ayah_endings += 1

                if curr_tokens:
                    require(
                        curr_sa_idx < len(lay_sa_list),
                        f"P{p}:L{line_idx} unassigned remaining tokens",
                    )
                    expected_s, expected_a = lay_sa_list[curr_sa_idx]
                    runs.append([expected_s, expected_a, " ".join(curr_tokens)])
                    curr_sa_idx += 1

                require(
                    curr_sa_idx == len(lay_sa_list),
                    f"P{p}:L{line_idx} SA list not fully consumed: {curr_sa_idx}/{len(lay_sa_list)}",
                )
                page_lines.append([centered, runs])

        output_pages.append(page_lines)

    require(len(output_pages) == 604, "Must output exactly 604 pages")
    require(total_ayah_endings == 6236, f"Expected 6236 ayah endings, got {total_ayah_endings}")
    require(total_surah_headers == 114, f"Expected 114 surah headers, got {total_surah_headers}")
    require(total_basmalas == 112, f"Expected 112 standalone basmalas, got {total_basmalas}")

    out_file = Path(output_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    compact_json = json.dumps(output_pages, ensure_ascii=False, separators=(",", ":"))
    out_file.write_bytes(compact_json.encode("utf-8"))
    print(f"Generated {output_path} successfully ({len(compact_json)} chars).")


if __name__ == "__main__":
    ts_file = ".dart_tool/old_madina_font_review/quran_text_old_madinah.ts"
    layout_file = "sorse/الطبعة القديمة 1405/New folder/qpc_v1_layout.json"
    alignment_file = "assets/data/qpc_v1_line_alignment.json"
    output_file = "assets/data/digital_khatt_old_madina.json"

    build(ts_file, layout_file, alignment_file, output_file)
