import json

data = json.load(open('assets/data/quran_glyphs.json', encoding='utf-8'))

# Check special cases
print("=== Special Cases Analysis ===\n")

# 1. Page 1 (الفاتحة)
print("1. Page 1 (الفاتحة):")
page1 = [p for p in data if p['page'] == 1][0]
for i, line in enumerate(page1['lines'][:3]):
    basmala = [g for g in line['glyphs'] if g.get('type') == 6]
    surah_name = [g for g in line['glyphs'] if g.get('type') == 8]
    print(f"  Line {i+1}: Basmala={len(basmala)}, SurahName={len(surah_name)}")

# 2. Page 187 (سورة التوبة/براءة)
print("\n2. Page 187 (سورة التوبة - براءة):")
page187 = [p for p in data if p['page'] == 187][0]
for i, line in enumerate(page187['lines'][:5]):
    basmala = [g for g in line['glyphs'] if g.get('type') == 6]
    surah_name = [g for g in line['glyphs'] if g.get('type') == 8]
    words = [g for g in line['glyphs'] if g.get('type') == 1]
    if basmala or surah_name or i < 3:
        print(f"  Line {i+1}: Basmala={len(basmala)}, SurahName={len(surah_name)}, Words={len(words)}")
