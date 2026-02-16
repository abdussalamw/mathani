#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
استخراج وتحليل ملفات QPC V1 المصدرية
"""

import os
import sys
import tarfile
import zipfile
import json
import sqlite3

# إعداد الـ stdout ليدعم UTF-8
sys.stdout.reconfigure(encoding='utf-8')

base_path = r'C:\Projects\New app\sorse\الطبعة القديمة 1405'

def extract_files():
    """استخراج جميع الملفات المضغوطة"""
    print("=" * 60)
    print("استخراج ملفات QPC V1")
    print("=" * 60)
    
    # استخراج tar.bz2
    tar_path = os.path.join(base_path, 'qpc_v1_by_page.tar.bz2')
    if os.path.exists(tar_path):
        print(f"\n[1] استخراج: qpc_v1_by_page.tar.bz2")
        with tarfile.open(tar_path, 'r:bz2') as tar:
            tar.extractall(base_path)
        print("    ✓ تم الاستخراج")
    
    # استخراج ملفات zip
    zip_files = [
        'qpc-v1-ayah-by-ayah-glyphs.json.zip',
        'qpc-v1-glyph-codes-wbw.json.zip',
        'qpc-v1-15-lines.db.zip'
    ]
    
    for i, zf in enumerate(zip_files, 2):
        zip_path = os.path.join(base_path, zf)
        if os.path.exists(zip_path):
            print(f"\n[{i}] استخراج: {zf}")
            with zipfile.ZipFile(zip_path, 'r') as zf_ref:
                zf_ref.extractall(base_path)
            print("    ✓ تم الاستخراج")
    
    print("\n" + "=" * 60)

def analyze_json_files():
    """تحليل ملفات JSON المستخرجة"""
    print("\nتحليل ملفات JSON:")
    print("-" * 40)
    
    json_files = [
        'qpc-v1-ayah-by-ayah-glyphs.json',
        'qpc-v1-glyph-codes-wbw.json'
    ]
    
    for jf in json_files:
        json_path = os.path.join(base_path, jf)
        if os.path.exists(json_path):
            print(f"\n📄 {jf}:")
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                print(f"   نوع البيانات: {type(data).__name__}")
                
                if isinstance(data, list):
                    print(f"   عدد العناصر: {len(data)}")
                    if len(data) > 0:
                        print(f"   عينة (أول عنصر):")
                        print(f"      {json.dumps(data[0], ensure_ascii=False, indent=6)[:500]}")
                
                elif isinstance(data, dict):
                    print(f"   عدد المفاتيح: {len(data)}")
                    sample_keys = list(data.keys())[:3]
                    print(f"   عينة من المفاتيح: {sample_keys}")
                    for k in sample_keys:
                        print(f"      {k}: {json.dumps(data[k], ensure_ascii=False)[:200]}")
                        
            except Exception as e:
                print(f"   ❌ خطأ: {e}")

def analyze_db():
    """تحليل قاعدة البيانات"""
    print("\n\nتحليل قاعدة البيانات:")
    print("-" * 40)
    
    db_path = os.path.join(base_path, 'qpc-v1-15-lines.db')
    if os.path.exists(db_path):
        print(f"\n📄 qpc-v1-15-lines.db:")
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # الحصول على قائمة الجداول
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            print(f"   الجداول: {[t[0] for t in tables]}")
            
            # فحص كل جدول
            for table in tables:
                table_name = table[0]
                cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = cursor.fetchone()[0]
                print(f"\n   جدول '{table_name}': {count} صف")
                
                # عينة من البيانات
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
                columns = [description[0] for description in cursor.description]
                rows = cursor.fetchall()
                
                print(f"      الأعمدة: {columns}")
                for i, row in enumerate(rows, 1):
                    print(f"      صف {i}: {row}")
            
            conn.close()
            
        except Exception as e:
            print(f"   ❌ خطأ: {e}")

def compare_with_current():
    """مقارنة مع ملف JSON الحالي في المشروع"""
    print("\n\nمقارنة مع ملف JSON الحالي:")
    print("-" * 40)
    
    current_path = r'C:\Projects\New app\mathani\assets\data\qpc_v1_glyphs.json'
    new_path = os.path.join(base_path, 'qpc-v1-glyph-codes-wbw.json')
    
    if os.path.exists(current_path) and os.path.exists(new_path):
        print("\n📊 المقارنة:")
        
        with open(current_path, 'r', encoding='utf-8') as f:
            current_data = json.load(f)
        
        with open(new_path, 'r', encoding='utf-8') as f:
            new_data = json.load(f)
        
        print(f"   الملف الحالي: {len(current_data)} إدخال")
        print(f"   الملف الجديد: {len(new_data)} إدخال")
        
        # مقارنة العينات
        if isinstance(current_data, dict) and isinstance(new_data, dict):
            current_keys = set(current_data.keys())
            new_keys = set(new_data.keys())
            
            common = current_keys & new_keys
            only_current = current_keys - new_keys
            only_new = new_keys - current_keys
            
            print(f"\n   مفاتيح مشتركة: {len(common)}")
            print(f"   مفاتيح فقط في الحالي: {len(only_current)}")
            print(f"   مفاتيح فقط في الجديد: {len(only_new)}")
            
            if common:
                sample_key = list(common)[0]
                print(f"\n   عينة مقارنة للمفتاح '{sample_key}':")
                print(f"      الحالي: {json.dumps(current_data[sample_key], ensure_ascii=False)[:100]}")
                print(f"      الجديد: {json.dumps(new_data[sample_key], ensure_ascii=False)[:100]}")

if __name__ == '__main__':
    extract_files()
    analyze_json_files()
    analyze_db()
    compare_with_current()
    
    print("\n" + "=" * 60)
    print("التحليل انتهى!")
    print("=" * 60)
