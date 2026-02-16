import zipfile
import os
import json

zip_path = r"C:\Projects\New app\sorse\الطبعة القديمة 1405\qpc-v1-glyph-codes-wbw.json.zip"
extract_path = "temp_json"

def inspect_json():
    try:
        # File is already extracted from previous run, but ok to re-extract or skip
        json_file = os.path.join(extract_path, "qpc-v1-glyph-codes-wbw.json")
        
        print(f"Inspecting JSON: {json_file}")
        
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            print("Types in JSON:", type(data))
            
            # Print structure
            if isinstance(data, list):
                print(f"List length: {len(data)}")
                print("First item:", json.dumps(data[0], ensure_ascii=True, indent=2))
            elif isinstance(data, dict):
                print(f"Dict keys: {list(data.keys())[:10]}")
                # Print a sample entry
                first_key = list(data.keys())[0]
                print(f"Sample [{first_key}]:", json.dumps(data[first_key], ensure_ascii=True, indent=2))
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_json()
