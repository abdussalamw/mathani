#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
إعادة بناء ملف qpc_v1_layout.json من قاعدة البيانات
"""

import json
import sqlite3
import sys
sys.stdout.reconfigure(encoding='utf-8')

# المسارات
glyphs_json_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_glyphs.json'
db_path = r'C:\Projects\New app\sorse\الطبعة القديمة 1405\qpc-v1-15-lines.db'
output_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_layout_new.json'

print('=' * 60)
print('إعادة بناء ملف التخطيط QPC V1')
print('=' * 60)

# 1. تحميل ملف glyphs
print('\n[1] تحميل ملف qpc_v1_glyphs.json...')
with open(glyphs_json_path, 'r', encoding='utf-8') as f:
    glyphs_data = json.load(f)
print(f'    عدد الإدخالات: {len(glyphs_data)}')

# 2. فهم هيكل glyphs
# المفاتيح: "surah:ayah:word" -> {"text": "glyph_char"}
print('\n[2] عينة من البيانات:')
sample_keys = list(glyphs_data.keys())[:3]
for k in sample_keys:
    print(f'    {k}: {glyphs_data[k]}')

# 3. إنشاء قاموس للبحث السريع
# نحتاج إلى معرفة: لكل (surah, ayah, word) ما هو الـ glyphد
print('\n[3] بناء فهرس البحث...')
glyph_index = {}  # (surah, ayah, word) -> glyph_char
for key, value in glyphs_data.items():
    parts = key.split(':')
    if len(parts) == 3:
        surah, ayah, word = int(parts[0]), int(parts[1]), int(parts[2])
        glyph_index[(surah, ayah, word)] = value.get('text', '')

print(f'    عدد العناصر في الفهرس: {len(glyph_index)}')

# 4. تحميل قاعدة البيانات وفهم هيكلها
print('\n[4] فحص قاعدة البيانات...')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# عرض هيكل الجدول
cursor.execute("PRAGMA table_info(pages)")
columns = cursor.fetchall()
print(f'    أعمدة جدول pages:')
for col in columns:
    print(f'      {col[1]} ({col[2]})')

# عرض عينة من البيانات
print('\n[5] عينة من بيانات قاعدة البيانات:')
cursor.execute("SELECT * FROM pages WHERE page_number = 1 ORDER BY line_number LIMIT 10")
rows = cursor.fetchall()
for row in rows:
    print(f'    {row}')

conn.close()

print('\n' + '=' * 60)
print('اكتمل الفحص. الآن نحتاج إلى فهم كيفية ربط البيانات.')
print('=' * 60)

# ملاحظة: قاعدة البيانات تحتوي على:
# - page_number, line_number, line_type, is_centered, first_word_id, last_word_id, surah_number
# لكنها لا تحتوي على تفاصيل الآيات والكلمات بشكل مباشر

print('\n⚠️  ملاحظة:')
print('قاعدة البيانات تحتوي على first_word_id و last_word_id')
print('لكنها لا تحتوي على mapping كامل للآيات والكلمات.')
print('\nالحل المقترح:')
print('1. استخدام قاعدة البيانات لفهم بنية الصفحات والأسطر')
print('2. استخدام ملف qpc-v1-ayah-by-ayah-glyphs.json لمعرفة توزيع الآيات')
print('3. بناء layout جديد يحتوي على surah, ayah, word لكل glyph')
