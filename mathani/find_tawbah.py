import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

print("=== Finding Surah 9 (التوبة) ===\n")

# Find which page has Surah 9
for page_num in range(187, 210):  # التوبة تبدأ حوالي صفحة 187
    page = [p for p in data if p['page'] == page_num]
    if not page:
        continue
    page = page[0]
    
    # Check first few lines
    for line in page['lines'][:3]:
        for glyph in line['glyphs']:
            if glyph.get('surah') == 9:
                print(f"Page {page_num}: Found Surah 9!")
                # Check for Basmala and Surah name
                basmala_count = sum(1 for l in page['lines'] for g in l['glyphs'] if g.get('type') == 6)
                surah_name_count = sum(1 for l in page['lines'] for g in l['glyphs'] if g.get('type') == 8)
                print(f"  Basmala count: {basmala_count}")
                print(f"  Surah name count: {surah_name_count}")
                
                # Show first line details
                first_line = page['lines'][0]
                print(f"  First line glyphs:")
                for g in first_line['glyphs'][:3]:
                    print(f"    Type {g.get('type')}: surah={g.get('surah')}, code={repr(g.get('code'))}")
                break
        else:
            continue
        break
    else:
        continue
    break
