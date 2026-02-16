#!/usr/bin/env python3
"""
سكربت لتحليل مشكلة QPC V1 Font
يكشف عن التطابق بين ملف JSON والخط الفعلي
"""

from fontTools.ttLib import TTFont
import json
import os

font_path = r'C:\Projects\New app\mathani\temp_font_extract\qpc_page_001.ttf'
glyphs_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_glyphs.json'

print("=" * 60)
print("تحليل مشكلة QPC V1 Font")
print("=" * 60)

# 1. فحص الخط
print("\n1. فحص ملف الخط:")
print("-" * 40)

if not os.path.exists(font_path):
    print(f"خطأ: ملف الخط غير موجود: {font_path}")
else:
    ft = TTFont(font_path)
    cmap = ft.getBestCmap()
    
    print(f"إجمالي الأحرف في CMAP: {len(cmap)}")
    
    # عرض جميع الأحرف (أول 50)
    print("\nعينة من الأحرف في الخط:")
    for i, (code, name) in enumerate(list(cmap.items())[:50]):
        char = chr(code) if 0 <= code <= 0x10FFFF else '?'
        print(f"  U+{code:04X} ({char!r}) -> {name}")
    
    # فحص نطاقات محددة
    print("\n\n2. فحص نطاقات الـ Unicode:")
    print("-" * 40)
    
    # Arabic Presentation Forms-A (FB50-FDFF)
    arabic_pres_a = [c for c in cmap if 0xFB50 <= c <= 0xFDFF]
    print(f"Arabic Presentation Forms-A (FB50-FDFF): {len(arabic_pres_a)} حرف")
    
    # Private Use Area (E000-F8FF)
    pua = [c for c in cmap if 0xE000 <= c <= 0xF8FF]
    print(f"Private Use Area (E000-F8FF): {len(pua)} حرف")
    
    # Basic Latin (0000-007F)
    latin = [c for c in cmap if 0x0000 <= c <= 0x007F]
    print(f"Basic Latin (0000-007F): {len(latin)} حرف")
    
    # عرض توزيع الـ Unicode
    print("\n\n3. توزيع الـ Unicode blocks:")
    print("-" * 40)
    from collections import Counter
    blocks = Counter()
    for code in cmap:
        if 0x0000 <= code <= 0x007F:
            blocks['Basic Latin'] += 1
        elif 0x0080 <= code <= 0x00FF:
            blocks['Latin-1 Supplement'] += 1
        elif 0x0600 <= code <= 0x06FF:
            blocks['Arabic'] += 1
        elif 0xFB50 <= code <= 0xFDFF:
            blocks['Arabic Presentation Forms-A'] += 1
        elif 0xFE70 <= code <= 0xFEFF:
            blocks['Arabic Presentation Forms-B'] += 1
        elif 0xE000 <= code <= 0xF8FF:
            blocks['Private Use Area'] += 1
        else:
            blocks[f'Other (U+{code//0x1000:01X}000)'] += 1
    
    for block, count in blocks.most_common():
        print(f"  {block}: {count}")

# 2. فحص ملف JSON
print("\n\n4. فحص ملف JSON:")
print("-" * 40)

if not os.path.exists(glyphs_path):
    print(f"خطأ: ملف JSON غير موجود: {glyphs_path}")
else:
    with open(glyphs_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"إجمالي الإدخالات في JSON: {len(data)}")
    
    # عرض عينة من الأحرف
    print("\nعينة من الأحرف في JSON (أول 10):")
    for i, (key, value) in enumerate(list(data.items())[:10]):
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str) and text:
            for char in text:
                code = ord(char)
                print(f"  {key}: '{char}' = U+{code:04X}")
    
    # فحص نطاقات الـ Unicode في JSON
    print("\n\n5. توزيع الـ Unicode في JSON:")
    print("-" * 40)
    
    all_chars = set()
    for value in data.values():
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str):
            all_chars.update(text)
    
    json_blocks = Counter()
    for char in all_chars:
        code = ord(char)
        if 0x0000 <= code <= 0x007F:
            json_blocks['Basic Latin'] += 1
        elif 0x0080 <= code <= 0x00FF:
            json_blocks['Latin-1 Supplement'] += 1
        elif 0x0600 <= code <= 0x06FF:
            json_blocks['Arabic'] += 1
        elif 0xFB50 <= code <= 0xFDFF:
            json_blocks['Arabic Presentation Forms-A'] += 1
        elif 0xFE70 <= code <= 0xFEFF:
            json_blocks['Arabic Presentation Forms-B'] += 1
        elif 0xE000 <= code <= 0xF8FF:
            json_blocks['Private Use Area'] += 1
        else:
            json_blocks[f'Other (U+{code//0x1000:01X}000)'] += 1
    
    for block, count in json_blocks.most_common():
        print(f"  {block}: {count}")

# 3. المقارنة
print("\n\n6. مقارنة JSON مع الخط:")
print("-" * 40)

if os.path.exists(font_path) and os.path.exists(glyphs_path):
    # هل الأحرف في JSON موجودة في الخط؟
    missing_in_font = []
    for value in data.values():
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str):
            for char in text:
                code = ord(char)
                if code not in cmap:
                    missing_in_font.append(char)
    
    if missing_in_font:
        print(f"أحرف في JSON ليست في الخط: {len(set(missing_in_font))} حرف فريد")
        print("  عينة:", list(set(missing_in_font))[:10])
    else:
        print("✓ جميع أحرف JSON موجودة في الخط")
    
    # هل الخط يحتوي على أحرف ليست في JSON؟
    json_codes = set()
    for value in data.values():
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str):
            for char in text:
                json_codes.add(ord(char))
    
    extra_in_font = [c for c in cmap if c not in json_codes]
    if extra_in_font:
        print(f"\nأحرف في الخط ليست في JSON: {len(extra_in_font)} حرف")
        print("  عينة:", [f"U+{c:04X}({chr(c)})" for c in extra_in_font[:10]])
    else:
        print("✓ جميع أحرف الخط موجودة في JSON")

print("\n" + "=" * 60)
print("التحليل انتهى")
print("=" * 60)
