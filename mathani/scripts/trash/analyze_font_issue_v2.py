#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
سكربت لتحليل مشكلة QPC V1 Font - النسخة المُحسَّنة
"""

from fontTools.ttLib import TTFont
import json
import os
import sys

# إعداد الـ stdout ليدعم UTF-8
sys.stdout.reconfigure(encoding='utf-8')

font_path = r'C:\Projects\New app\mathani\temp_font_extract\qpc_page_001.ttf'
glyphs_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_glyphs.json'

print("=" * 70)
print("تحليل مشكلة QPC V1 Font")
print("=" * 70)

# 1. فحص الخط
print("\n[1] فحص ملف الخط:")
print("-" * 50)

if not os.path.exists(font_path):
    print(f"خطأ: ملف الخط غير موجود: {font_path}")
else:
    ft = TTFont(font_path)
    cmap = ft.getBestCmap()
    
    print(f"إجمالي الأحرف في CMAP: {len(cmap)}")
    
    # فحص نطاقات محددة
    from collections import Counter
    blocks = Counter()
    arabic_pres_a = []
    arabic_pres_b = []
    arabic_basic = []
    
    for code in cmap:
        if 0x0600 <= code <= 0x06FF:
            blocks['Arabic (0600-06FF)'] += 1
            arabic_basic.append(code)
        elif 0xFB50 <= code <= 0xFDFF:
            blocks['Arabic Presentation Forms-A (FB50-FDFF)'] += 1
            arabic_pres_a.append(code)
        elif 0xFE70 <= code <= 0xFEFF:
            blocks['Arabic Presentation Forms-B (FE70-FEFF)'] += 1
            arabic_pres_b.append(code)
        elif 0x0000 <= code <= 0x007F:
            blocks['Basic Latin'] += 1
        elif 0x0080 <= code <= 0x00FF:
            blocks['Latin-1 Supplement'] += 1
        elif 0xE000 <= code <= 0xF8FF:
            blocks['Private Use Area'] += 1
    
    print("\nتوزيع الـ Unicode blocks:")
    for block, count in blocks.most_common():
        print(f"  {block}: {count} حرف")
    
    # عرض عينة من Arabic Presentation Forms-A
    print(f"\nعينة من Arabic Presentation Forms-A (أول 20):")
    arabic_pres_a.sort()
    for code in arabic_pres_a[:20]:
        char = chr(code)
        name = cmap[code]
        print(f"  U+{code:04X} -> glyph: {name}")

# 2. فحص ملف JSON
print("\n" + "=" * 70)
print("\n[2] فحص ملف JSON:")
print("-" * 50)

if not os.path.exists(glyphs_path):
    print(f"خطأ: ملف JSON غير موجود: {glyphs_path}")
else:
    with open(glyphs_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"إجمالي الإدخالات في JSON: {len(data)}")
    
    # عرض عينة من الأحرف
    print("\nعينة من الأحرف في JSON (أول 15 إدخال):")
    for i, (key, value) in enumerate(list(data.items())[:15]):
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str) and text:
            codes = [f"U+{ord(c):04X}" for c in text]
            print(f"  {key}: '{text}' = {', '.join(codes)}")
    
    # فحص نطاقات الـ Unicode في JSON
    print("\n\n[3] توزيع الـ Unicode في JSON:")
    print("-" * 50)
    
    all_chars = set()
    for value in data.values():
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str):
            all_chars.update(text)
    
    json_blocks = Counter()
    json_arabic_pres_a = []
    
    for char in all_chars:
        code = ord(char)
        if 0x0600 <= code <= 0x06FF:
            json_blocks['Arabic (0600-06FF)'] += 1
        elif 0xFB50 <= code <= 0xFDFF:
            json_blocks['Arabic Presentation Forms-A (FB50-FDFF)'] += 1
            json_arabic_pres_a.append(code)
        elif 0xFE70 <= code <= 0xFEFF:
            json_blocks['Arabic Presentation Forms-B (FE70-FEFF)'] += 1
        elif 0x0000 <= code <= 0x007F:
            json_blocks['Basic Latin'] += 1
        elif 0xE000 <= code <= 0xF8FF:
            json_blocks['Private Use Area'] += 1
        else:
            json_blocks[f'Other'] += 1
    
    for block, count in json_blocks.most_common():
        print(f"  {block}: {count} حرف فريد")
    
    print(f"\nمجموع الأحرف الفريدة في JSON: {len(all_chars)}")

# 3. المقارنة
print("\n" + "=" * 70)
print("\n[4] مقارنة JSON مع الخط:")
print("-" * 50)

if os.path.exists(font_path) and os.path.exists(glyphs_path):
    font_codes = set(cmap.keys())
    json_codes = set()
    for value in data.values():
        text = value.get('text', '') if isinstance(value, dict) else value
        if isinstance(text, str):
            for char in text:
                json_codes.add(ord(char))
    
    # أحرف في JSON ليست في الخط
    missing_in_font = json_codes - font_codes
    if missing_in_font:
        print(f"⚠️  أحرف في JSON ليست في الخط: {len(missing_in_font)} حرف فريد")
        print("   عينة (أول 10):")
        for code in sorted(missing_in_font)[:10]:
            print(f"     U+{code:04X}")
    else:
        print("✓ جميع أحرف JSON موجودة في الخط")
    
    # أحرف في الخط ليست في JSON
    extra_in_font = font_codes - json_codes
    if extra_in_font:
        print(f"\n⚠️  أحرف في الخط ليست في JSON: {len(extra_in_font)} حرف")
        # تصفية فقط Arabic Presentation Forms
        extra_arabic = [c for c in extra_in_font if 0xFB50 <= c <= 0xFDFF or 0xFE70 <= c <= 0xFEFF]
        if extra_arabic:
            print(f"   منها {len(extra_arabic)} في نطاق Arabic Presentation Forms")
            print("   عينة:")
            for code in sorted(extra_arabic)[:10]:
                print(f"     U+{code:04X} (glyph: {cmap[code]})")
    else:
        print("✓ جميع أحرف الخط موجودة في JSON")
    
    # التداخل
    common = json_codes & font_codes
    print(f"\n📊 الأحرف المشتركة: {len(common)}")
    print(f"📊 نسبة التغطية: {len(common)}/{len(json_codes)} = {len(common)/len(json_codes)*100:.1f}%")

print("\n" + "=" * 70)
print("التحليل انتهى")
print("=" * 70)
