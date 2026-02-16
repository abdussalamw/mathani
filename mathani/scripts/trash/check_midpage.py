import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

print("=== Checking if Basmala appears mid-page ===\n")

# Check a few pages where surahs start mid-page
test_cases = [
    (50, 3, "Al-Imran"),  # صفحة 50، سورة آل عمران
    (106, 5, "Al-Ma'idah"),  # صفحة 106، سورة المائدة
]

for page_num, expected_surah, surah_name in test_cases:
    page = [p for p in data if p['page'] == page_num][0]
    
    print(f"Page {page_num} ({surah_name}, Surah {expected_surah}):")
    
    # Check ALL lines for Basmala
    for i, line in enumerate(page['lines']):
        basmala = [g for g in line['glyphs'] if g.get('type') == 6]
        surah_name_glyph = [g for g in line['glyphs'] if g.get('type') == 8]
        
        if basmala or surah_name_glyph:
            print(f"  Line {i+1}: Basmala={len(basmala)}, SurahName={len(surah_name_glyph)}")
            if basmala:
                print(f"    Basmala code: {repr(basmala[0].get('code'))}, surah: {basmala[0].get('surah')}")
    
    print()

# الخلاصة
print("="*50)
print("CONCLUSION:")
print("If Basmala appears mid-page, the solution is OK.")
print("If NOT, we need to INSERT Basmala programmatically!")
print("="*50)
