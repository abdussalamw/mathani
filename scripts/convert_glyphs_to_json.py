import csv
import json
from collections import defaultdict

def convert_csv_to_json():
    """
    Convert TB_Glyph.csv to JSON organized by pages
    """
    print("Converting TB_Glyph.csv to JSON...")
    
    # Read CSV
    pages_data = defaultdict(lambda: defaultdict(list))
    
    with open('sorse/TB_Glyph.csv', 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        row_count = 0
        
        for row in reader:
            row_count += 1
            if row_count % 10000 == 0:
                print(f"   Processing row {row_count:,}...")
            
            page_num = int(row['page_number']) if row['page_number'] else 0
            line_num = int(row['line_number']) if row['line_number'] else 0
            
            # تنظيف البيانات
            glyph_entry = {
                'id': int(row['ID']) if row['ID'] else 0,
                'code': row['glyph_code'] if row['glyph_code'] else '',
                'type': int(row['glyph_type_id']) if row['glyph_type_id'] else 0,
                'order': int(row['order']) if row['order'] else 0,
            }
            
            # إضافة معلومات اختيارية
            if row['word_id']:
                glyph_entry['word_id'] = int(row['word_id'])
            if row['sura_number']:
                glyph_entry['surah'] = int(row['sura_number'])
            if row['ayah_number']:
                glyph_entry['ayah'] = int(row['ayah_number'])
            
            pages_data[page_num][line_num].append(glyph_entry)
    
    print(f"[OK] Read {row_count:,} rows")
    
    # Convert to organized list
    output = []
    for page_num in sorted(pages_data.keys()):
        if page_num == 0:  # Skip undefined pages
            continue
            
        page_obj = {
            'page': page_num,
            'lines': []
        }
        
        for line_num in sorted(pages_data[page_num].keys()):
            if line_num == 0:
                continue
                
            line_obj = {
                'line': line_num,
                'glyphs': sorted(pages_data[page_num][line_num], key=lambda x: x['order'])
            }
            page_obj['lines'].append(line_obj)
        
        output.append(page_obj)
    
    # حفظ JSON
    output_file = 'mathani/assets/data/quran_glyphs.json'
    with open(output_file, 'w', encoding='utf-8') as jsonfile:
        json.dump(output, jsonfile, ensure_ascii=False, separators=(',', ':'))
    
    print(f"[OK] Saved to: {output_file}")
    print(f"[INFO] Total pages: {len(output)}")
    
    # Statistics
    total_glyphs = sum(len(line['glyphs']) for page in output for line in page['lines'])
    print(f"[INFO] Total glyphs: {total_glyphs:,}")
    
    # Save compressed version
    import gzip
    output_gz = output_file + '.gz'
    with gzip.open(output_gz, 'wt', encoding='utf-8') as gzfile:
        json.dump(output, gzfile, ensure_ascii=False, separators=(',', ':'))
    
    import os
    original_size = os.path.getsize(output_file) / (1024 * 1024)
    compressed_size = os.path.getsize(output_gz) / (1024 * 1024)
    
    print(f"[INFO] JSON size: {original_size:.2f} MB")
    print(f"[INFO] JSON.GZ size: {compressed_size:.2f} MB ({compressed_size/original_size*100:.1f}%)")
    print("[SUCCESS] Conversion completed!")

if __name__ == '__main__':
    convert_csv_to_json()
