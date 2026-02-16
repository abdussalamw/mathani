import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

# Check page 128 structure again
page128 = [p for p in data if p['page'] == 128][0]

print("=== Page 128 Detailed Analysis ===\n")

for i, line in enumerate(page128['lines'][:5]):
    print(f"Line {i+1}:")
    for j, glyph in enumerate(line['glyphs']):
        glyph_type = glyph.get('type', 'unknown')
        type_name = {
            6: 'BASMALA',
            8: 'SURAH_NAME',
            2: 'AYAH_END',
            1: 'WORD'
        }.get(glyph_type, f'TYPE_{glyph_type}')
        
        print(f"  [{j}] {type_name}: surah={glyph.get('surah')}, code={repr(glyph.get('code', ''))[:20]}")
    print()
