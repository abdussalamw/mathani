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
    with open(json_path, 'r', encoding='utf-8') as f:
        glyph_data = json.load(f)
    print(f"JSON Key Count: {len(glyph_data)}")
    
    # 2. Connect DB
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 3. Inspect Page 1
    print("\n--- Inspecting Page 1 ---")
    inspect_page(cursor, glyph_data, 1)
    
    # 4. Inspect Page 2
    print("\n--- Inspecting Page 2 ---")
    inspect_page(cursor, glyph_data, 2)
    
    conn.close()

def inspect_page(cursor, glyph_data, page_num):
    # Get Lines
    cursor.execute("SELECT line_number, line_type, first_word_id, last_word_id, surah_number FROM pages WHERE page_number = ? ORDER BY line_number", (page_num,))
    lines = cursor.fetchall()
    
    print(f"DB Lines for Page {page_num}: {len(lines)}")
    
    current_surah = None
    
    for line in lines:
        line_num, line_type, first_wid, last_wid, surah = line
        print(f"Line {line_num} ({line_type}): Words {first_wid}-{last_wid}")
        
        if line_type == 'surah_name':
             print(f"  [Header] Surah {surah}")
             current_surah = surah 
             continue
             
        if line_type == 'basmala':
             print(f"  [Header] Basmala")
             continue
             
        # It's 'ayah' line
        # We need to know WHICH Surah/Ayah/Word these IDs correspond to.
        # The DB *doesn't* seem to have Surah/Ayah for each word directly in `pages` table?
        # Let's check if there's a `words` table or similar.
        # Inspecting schema again helper.
        pass

    # Check Glyph JSON for this page
    # JSON keys are "S:A:W".
    # We need to scan keys to find those on this page.
    # Since we don't know exact S:A mapping from DB easily without `words` table,
    # let's just look at Surah 1 for Page 1.
    
    if page_num == 1:
        print("  JSON Content for Surah 1:")
        for ayah in range(1, 8):
            for word in range(1, 10): # heuristic
                key = f"1:{ayah}:{word}"
                if key in glyph_data:
                    val = glyph_data[key]
                    text = val.get('text', '?') if isinstance(val, dict) else val
                    print(f"    {key} -> {text}")
    
    if page_num == 2:
         print("  JSON Content for Surah 2 (First few):")
         for ayah in range(1, 6):
            for word in range(1, 10):
                key = f"2:{ayah}:{word}"
                if key in glyph_data:
                     val = glyph_data[key]
                     text = val.get('text', '?') if isinstance(val, dict) else val
                     print(f"    {key} -> {text}")

if __name__ == "__main__":
    debug_data()
