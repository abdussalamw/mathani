import sqlite3
import json
import os

db_path = "assets/data/qpc_v1_layout.db"
json_path = "assets/data/qpc_v1_glyphs.json"

def debug_data():
    if not os.path.exists(db_path):
        print(f"DB not found at {db_path}")
        return
    if not os.path.exists(json_path):
        print(f"JSON not found at {json_path}")
        return

    # 1. Load JSON
    print("Loading JSON...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            glyph_data = json.load(f)
        print(f"JSON Key Count: {len(glyph_data)}")
        
        # Check first key
        first = next(iter(glyph_data))
        val = glyph_data[first]
        if isinstance(val, dict):
            print(f"Sample Val format keys: {list(val.keys())}")
            
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return
    
    # 2. Connect DB
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    inspect_page(cursor, glyph_data, 1)
    
    conn.close()

def inspect_page(cursor, glyph_data, page_num):
    print(f"\n--- Inspecting Page {page_num} ---")
    cursor.execute("SELECT line_number, line_type, first_word_id, last_word_id, surah_number FROM pages WHERE page_number = ? ORDER BY line_number", (page_num,))
    lines = cursor.fetchall()
    
    db_word_count = 0
    
    for line in lines:
        line_num, line_type, first_wid, last_wid, surah = line
        print(f"Line {line_num}: {line_type} Words:{first_wid}-{last_wid}")
        
        if line_type == 'ayah':
            if first_wid and last_wid:
                count = (last_wid - first_wid) + 1
                db_word_count += count

    print(f"Total Words on Page {page_num} according to DB: {db_word_count}")

    # Inspect JSON values for Surah 1
    print("JSON Sample Values (Hex):")
    # Surah 1 has 7 ayahs.
    # Ayah 1: 4 words?
    
    for ayah in range(1, 8):
        for word in range(1, 10):
            key = f"1:{ayah}:{word}"
            if key in glyph_data:
                val = glyph_data[key]
                text = val['text'] if isinstance(val, dict) else val
                
                # Print HEX codes only
                hex_codes = [hex(ord(c)) for c in text]
                print(f"  {key} -> {hex_codes}")

    except Exception as e:
        print(f"Error: {e}") 

if __name__ == "__main__":
    debug_data()
