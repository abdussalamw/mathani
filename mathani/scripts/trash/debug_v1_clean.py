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
             # Print keys only
             print(f"Sample Val Keys: {list(val.keys())}")
            
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return
    
    # 2. Connect DB
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    inspect_page(cursor, glyph_data, 1)
    inspect_page(cursor, glyph_data, 2)
    
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
            if first_wid is not None and last_wid is not None and first_wid != '':
                 # Handle empty string or None
                 try:
                    f = int(first_wid)
                    l = int(last_wid)
                    count = (l - f) + 1
                    db_word_count += count
                 except:
                    pass

    print(f"Total Words on Page {page_num} according to DB: {db_word_count}")

    # Inspect JSON values
    print("JSON Sample Values (Hex):")
    # Just print first 10 keys found for this page's surah?
    # Page 1 -> Surah 1.
    # Page 2 -> Surah 2.
    
    target_surah = 1 if page_num == 1 else 2
    
    for ayah in range(1, 6):
        for word in range(1, 10):
            key = f"{target_surah}:{ayah}:{word}"
            if key in glyph_data:
                val = glyph_data[key]
                text = val['text'] if isinstance(val, dict) else val
                
                # Print HEX codes only - safe for console
                hex_codes = [hex(ord(c)) for c in text]
                print(f"  {key} -> {hex_codes}")

if __name__ == "__main__":
    debug_data()
