import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

pages_to_check = [1, 2, 50, 77, 128]

for page_num in pages_to_check:
    page = [p for p in data if p['page'] == page_num][0]
    surah_name = [g for line in page['lines'] for g in line['glyphs'] if g.get('type') == 8]
    if surah_name:
        print(f"Page {page_num}: {surah_name[0]}")
    else:
        print(f"Page {page_num}: No Surah Name")
