import zipfile
import os
import json

zip_path = r"C:\Projects\New app\sorse\الطبعة القديمة 1405\qpc-v1-glyph-codes-wbw.json.zip"
extract_path = "temp_json"

def inspect_json():
    try:
        # Extract
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
            extracted_files = zip_ref.namelist()
            print(f"Extracted: {extracted_files}")
            
        json_file = os.path.join(extract_path, extracted_files[0])
        print(f"Inspecting JSON: {json_file}")
        
        with open(json_file, 'r', encoding='utf-8') as f:
            # Read first 1000 chars to peek structure
            content = f.read(2000)
            print("First 2000 chars:")
            print(content)
            
            # Try to load full if needed, but for now peek is enough to see structure.
            # If structure is list of objects, we can see keys.
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if not os.path.exists(extract_path):
        os.makedirs(extract_path)
    inspect_json()
