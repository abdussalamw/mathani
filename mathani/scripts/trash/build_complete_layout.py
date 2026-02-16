#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
بناء ملف التخطيط الكامل لـ QPC V1
باستخدام البيانات من المصادر الأصلية
"""

import json
import sqlite3
import sys
sys.stdout.reconfigure(encoding='utf-8')

# المسارات
sources_path = r'C:\Projects\New app\sorse\الطبعة القديمة 1405'
mathani_data_path = r'C:\Projects\New app\mathani\assets\data'

ayah_by_ayah_path = f'{sources_path}/qpc-v1-ayah-by-ayah-glyphs.json'
glyphs_wbw_path = f'{sources_path}/qpc-v1-glyph-codes-wbw.json'
db_path = f'{sources_path}/qpc-v1-15-lines.db'

output_layout_path = f'{mathani_data_path}/qpc_v1_layout_complete.json'

print('=' * 70)
print('بناء ملف التخطيط الكامل لـ QPC V1')
print('=' * 70)

# 1. تحميل ملف الآية بالآية (يحتوي على رقم الصفحة لكل آية)
print('\n[1] تحميل ملف الآية بالآية...')
with open(ayah_by_ayah_path, 'r', encoding='utf-8') as f:
    ayah_data = json.load(f)
print(f'    عدد الآيات: {len(ayah_data)}')

# عينة
sample = list(ayah_data.items())[:2]
for k, v in sample:
    print(f'    {k}: {v}')

# 2. تحميل ملف الكلمات
print('\n[2] تحميل ملف الكلمات...')
with open(glyphs_wbw_path, 'r', encoding='utf-8') as f:
    glyphs_data = json.load(f)
print(f'    عدد الكلمات: {len(glyphs_data)}')

# 3. بناء هيكل الصفحات
print('\n[3] بناء هيكل الصفحات...')

# نحتاج إلى: لكل صفحة، نعرف الآيات الموجودة فيها
# من ثم نبني الأسطر بناءً على قاعدة البيانات

# 3.1 تجميع الآيات حسب الصفحة
page_ayahs = {}  # page_number -> list of (surah, ayah, text)
for verse_key, verse_info in ayah_data.items():
    page = verse_info.get('page_number', 0)
    if page not in page_ayahs:
        page_ayahs[page] = []
    page_ayahs[page].append({
        'surah': verse_info['surah'],
        'ayah': verse_info['ayah'],
        'text': verse_info['text'],
        'verse_key': verse_key
    })

print(f'    عدد الصفحات: {len(page_ayahs)}')
print(f'    عينة - الصفحة 1: {len(page_ayahs.get(1, []))} آية')

# 3.2 تحميل قاعدة البيانات لفهم بنية الأسطر
print('\n[4] تحليل بنية الأسطر من قاعدة البيانات...')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT * FROM pages ORDER BY page_number, line_number")
all_lines = cursor.fetchall()
conn.close()

print(f'    إجمالي الأسطر: {len(all_lines)}')

# تجميع الأسطر حسب الصفحة
db_pages = {}
for row in all_lines:
    page_num, line_num, line_type, is_centered, first_word_id, last_word_id, surah_num = row
    if page_num not in db_pages:
        db_pages[page_num] = []
    db_pages[page_num].append({
        'line_number': line_num,
        'line_type': line_type,
        'is_centered': bool(is_centered),
        'first_word_id': first_word_id,
        'last_word_id': last_word_id,
        'surah_number': surah_num
    })

print(f'    عدد الصفحات في DB: {len(db_pages)}')

# 4. بناء Layout كامل
print('\n[5] بناء Layout كامل...')

# نحتاج إلى matching بين:
# - page_ayahs: الآيات في كل صفحة (مع نصوصها)
# - db_pages: بنية الأسطر في كل صفحة
# - glyphs_data: كلمة بكلمة mapping

def get_words_for_ayah(surah, ayah):
    """الحصول على كلمات آية محددة"""
    words = []
    # ابحث عن جميع الكلمات في هذه الآية
    for key, value in glyphs_data.items():
        parts = key.split(':')
        if len(parts) == 3:
            s, a, w = int(parts[0]), int(parts[1]), int(parts[2])
            if s == surah and a == ayah:
                words.append({
                    'word': w,
                    'text': value['text'],
                    'key': key
                })
    # رتب حسب رقم الكلمة
    words.sort(key=lambda x: x['word'])
    return words

# بناء الـ layout
layout = {}

for page_num in sorted(page_ayahs.keys()):
    ayahs_in_page = page_ayahs[page_num]
    lines_in_page = db_pages.get(page_num, [])
    
    page_lines = []
    
    for line_info in lines_in_page:
        line_type = line_info['line_type']
        line_glyphs = []
        
        if line_type == 'surah_name':
            # اسم السورة
            surah_num = line_info['surah_number']
            if surah_num:
                line_glyphs.append({
                    't': 6,  # type 6 = surah name
                    's': surah_num,
                    'a': 0,
                    'w': 0
                })
        
        elif line_type == 'basmala':
            # البسملة
            # نحتاج إلى معرفة السورة
            if ayahs_in_page:
                first_ayah = ayahs_in_page[0]
                line_glyphs.append({
                    't': 8,  # type 8 = basmala
                    's': first_ayah['surah'],
                    'a': 0,
                    'w': 0
                })
        
        elif line_type == 'ayah':
            # آية عادية - نحتاج إلى توزيع الكلمات على الأسطر
            # هذا الجزء معقد لأننا نحتاج إلى معرفة أي كلمات تنتمي لأي سطر
            # حل مؤقت: نضع جميع كلمات الصفحة في السطر الأول فقط
            # TODO: تحسين هذا لاحقًا
            pass
        
        page_lines.append(line_glyphs)
    
    layout[str(page_num)] = page_lines

print(f'    تم بناء {len(layout)} صفحة')

# 5. حفظ الملف (نسخة أولية)
print('\n[6] حفظ الملف...')
with open(output_layout_path, 'w', encoding='utf-8') as f:
    json.dump(layout, f, ensure_ascii=False, indent=2)

print(f'    ✓ تم الحفظ في: {output_layout_path}')

print('\n' + '=' * 70)
print('ملاحظة: هذا إصدار أولي. يحتاج إلى تحسين توزيع الكلمات على الأسطر.')
print('=' * 70)
