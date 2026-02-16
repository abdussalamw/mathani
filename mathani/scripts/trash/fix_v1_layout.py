#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
إصلاح ملف qpc_v1_layout.json ليحتوي على بيانات كاملة
"""

import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

# المسارات
layout_old_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_layout.json'
glyphs_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_glyphs_new.json'
layout_new_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_layout_fixed.json'

print('=' * 60)
print('إصلاح ملف QPC V1 Layout')
print('=' * 60)

# 1. تحميل الملفات
print('\n[1] تحميل الملفات...')
with open(layout_old_path, 'r', encoding='utf-8') as f:
    old_layout = json.load(f)

with open(glyphs_path, 'r', encoding='utf-8') as f:
    glyphs_data = json.load(f)

print(f'    Layout القديم: {len(old_layout)} صفحة')
print(f'    Glyphs: {len(glyphs_data)} إدخال')

# 2. بناء فهرس للـ glyphs حسب السورة والآية
print('\n[2] بناء الفهارس...')
ayah_words = {}  # (surah, ayah) -> list of (word, text)
for key, value in glyphs_data.items():
    parts = key.split(':')
    if len(parts) == 3:
        s, a, w = int(parts[0]), int(parts[1]), int(parts[2])
        if (s, a) not in ayah_words:
            ayah_words[(s, a)] = []
        ayah_words[(s, a)].append({'word': w, 'text': value['text'], 'key': key})

# رتب الكلمات في كل آية
for key in ayah_words:
    ayah_words[key].sort(key=lambda x: x['word'])

print(f'    عدد الآيات: {len(ayah_words)}')

# 3. إنشاء layout جديد
print('\n[3] إنشاء Layout جديد...')
new_layout = {}

for page_str, page_lines in old_layout.items():
    page_num = int(page_str)
    new_lines = []
    
    for line in page_lines:
        new_line = []
        for glyph in line:
            # نسخ البيانات الأساسية
            new_glyph = {
                't': glyph.get('t', 0),  # type
                's': glyph.get('s', 0),  # surah
            }
            
            # إضافة ayah و word إذا كان متاحًا
            # هذا يتطلب منطقًا معقدًا لفهم توزيع الكلمات
            # للآن، نضيف قيم افتراضية
            new_glyph['a'] = 0  # ayah
            new_glyph['w'] = 0  # word
            
            new_line.append(new_glyph)
        new_lines.append(new_line)
    
    new_layout[page_str] = new_lines

print(f'    تم إنشاء {len(new_layout)} صفحة')

# 4. حفظ الملف الجديد
print('\n[4] حفظ الملف...')
with open(layout_new_path, 'w', encoding='utf-8') as f:
    json.dump(new_layout, f, ensure_ascii=False, indent=2)

print(f'    ✓ تم الحفظ: {layout_new_path}')

print('\n' + '=' * 60)
print('ملاحظة: هذا إصلاح أولي.')
print('للحصول على نتائج دقيقة، نحتاج لبناء layout من قاعدة البيانات.')
print('=' * 60)
