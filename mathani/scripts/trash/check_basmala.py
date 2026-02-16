import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

# Check page 128 (الأنعام)
page128 = [p for p in data if p['page'] == 128][0]

print(f"=== Page 128 Analysis ===")
print(f"Total lines: {len(page128['lines'])}")

for i, line in enumerate(page128['lines'][:5]):  # First 5 lines
    print(f"\nLine {i+1}: {len(line['glyphs'])} glyphs")
    for j, glyph in enumerate(line['glyphs'][:3]):  # First 3 glyphs per line
        glyph_type = glyph.get('type', 'unknown')
        type_name = {
            6: 'BASMALA',
            8: 'SURAH_NAME',
            2: 'AYAH_END',
            1: 'WORD'
        }.get(glyph_type, f'TYPE_{glyph_type}')
        
        code_repr = repr(glyph.get('code', ''))
        print(f"  [{j}] {type_name}: code={code_repr}, surah={glyph.get('surah')}, ayah={glyph.get('ayah')}")
