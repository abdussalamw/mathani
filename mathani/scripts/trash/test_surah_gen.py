import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

# Test the Surah name generation logic
page128 = [p for p in data if p['page'] == 128][0]

print("=== Testing Surah Name Generation ===\n")

for line in page128['lines'][:3]:
    for glyph in line['glyphs']:
        if glyph.get('type') == 8:  # Surah name
            surah_num = glyph.get('surah')
            code = glyph.get('code', '')
            
            print(f"Surah Name Glyph Found:")
            print(f"  Surah Number: {surah_num}")
            print(f"  Original Code: {repr(code)}")
            
            if code == '' and surah_num:
                # Generate code
                surah_code = 0xE000 + (surah_num - 1)
                generated = chr(surah_code)
                print(f"  Generated Code: {repr(generated)}")
                print(f"  Hex: {hex(surah_code)}")
                print(f"  Should display as Surah name for Surah {surah_num}")
            print()
