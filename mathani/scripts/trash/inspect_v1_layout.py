import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

layout_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_layout.json'

print('فحص ملف qpc_v1_layout.json')
print('=' * 50)

try:
    with open(layout_path, 'r', encoding='utf-8') as f:
        layout = json.load(f)
    
    print(f'عدد الصفحات: {len(layout)}')
    
    if '1' in layout:
        page1 = layout['1']
        print(f'الصفحة 1: {len(page1)} سطر')
        for i, line in enumerate(page1[:3], 1):
            print(f'  سطر {i}: {len(line)} عنصر')
            if line and i == 1:
                print(f'    أول عنصر: {line[0]}')
    
    # فحص هيكل البيانات
    print('\nفحص هيكل البيانات:')
    sample_page = layout.get('1', [])
    if sample_page and len(sample_page) > 0:
        sample_line = sample_page[0]
        if sample_line and len(sample_line) > 0:
            sample_glyph = sample_line[0]
            print(f'  هيكل Glyph: {sample_glyph}')
            print(f'  المفاتيح: {list(sample_glyph.keys())}')
    
except Exception as e:
    print(f'خطأ: {e}')
