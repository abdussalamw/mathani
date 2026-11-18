"""
prepare_release.py
==================
يُجهّز نموذج تدبر للرفع على GitHub Releases بثلاث حزم:
  1. tadabur-whisper-android-ios.zip  → للجوال (Android + iOS) - int8 مضغوط
  2. tadabur-whisper-desktop.zip      → للويندوز / ماك / لينوكس - float32
  3. tadabur-tokens.txt               → ملف المفردات (مشترك)

الاستخدام:
  python prepare_release.py
"""

import os
import shutil
import zipfile

# -------------------------
# الإعدادات
# -------------------------
ONNX_DIR = "onnx_model"
OUTPUT_DIR = "release_files"
ENCODER_SRC = os.path.join(ONNX_DIR, "encoder_model.onnx")
DECODER_SRC = os.path.join(ONNX_DIR, "decoder_model.onnx")
TOKENIZER_JSON = os.path.join(ONNX_DIR, "tokenizer.json")

os.makedirs(OUTPUT_DIR, exist_ok=True)

def file_size_mb(path):
    return os.path.getsize(path) / (1024 * 1024)

# -------------------------
# الخطوة 1: ضغط النماذج إلى int8 (للجوال)
# -------------------------
print("\n=== الخطوة 1: ضغط النماذج (int8 quantization) ===")
print("هذا يقلل الحجم بنسبة ~75% مع الحفاظ على الدقة...")

encoder_int8 = os.path.join(OUTPUT_DIR, "encoder.int8.onnx")
decoder_int8 = os.path.join(OUTPUT_DIR, "decoder.int8.onnx")

if not os.path.exists(encoder_int8):
    from onnxruntime.quantization import quantize_dynamic, QuantType
    print(f"  Quantizing encoder ({file_size_mb(ENCODER_SRC):.0f} MB) ...")
    quantize_dynamic(ENCODER_SRC, encoder_int8, weight_type=QuantType.QInt8)
    print(f"  Done! -> {file_size_mb(encoder_int8):.0f} MB")
else:
    print(f"  Encoder int8 already exists ({file_size_mb(encoder_int8):.0f} MB)")

if not os.path.exists(decoder_int8):
    from onnxruntime.quantization import quantize_dynamic, QuantType
    print(f"  Quantizing decoder ({file_size_mb(DECODER_SRC):.0f} MB) ...")
    quantize_dynamic(DECODER_SRC, decoder_int8, weight_type=QuantType.QInt8)
    print(f"  Done! -> {file_size_mb(decoder_int8):.0f} MB")
else:
    print(f"  Decoder int8 already exists ({file_size_mb(decoder_int8):.0f} MB)")

# -------------------------
# الخطوة 2: إنشاء ملف المفردات tokens.txt
# -------------------------
print("\n=== الخطوة 2: إنشاء ملف المفردات (tokens.txt) ===")
tokens_path = os.path.join(OUTPUT_DIR, "tokens.txt")

import json
with open(TOKENIZER_JSON, "r", encoding="utf-8") as f:
    tokenizer_data = json.load(f)

vocab = tokenizer_data.get("model", {}).get("vocab", {})
if not vocab:
    # محاولة أخرى للتنسيق المختلف
    vocab = tokenizer_data.get("vocab", {})

if vocab:
    # ترتيب حسب الرقم
    sorted_vocab = sorted(vocab.items(), key=lambda x: x[1])
    with open(tokens_path, "w", encoding="utf-8") as f:
        for token, idx in sorted_vocab:
            f.write(f"{token} {idx}\n")
    print(f"  تم إنشاء tokens.txt ({len(sorted_vocab)} كلمة)")
else:
    # استخدام الـ tokenizer مباشرة
    from transformers import AutoTokenizer
    print("  تحميل المفردات من النموذج الأصلي...")
    tokenizer = AutoTokenizer.from_pretrained("FaisaI/tadabur-Whisper-Small")
    vocab = tokenizer.get_vocab()
    sorted_vocab = sorted(vocab.items(), key=lambda x: x[1])
    with open(tokens_path, "w", encoding="utf-8") as f:
        for token, idx in sorted_vocab:
            f.write(f"{token} {idx}\n")
    print(f"  تم إنشاء tokens.txt ({len(sorted_vocab)} كلمة)")

# -------------------------
# الخطوة 3: تحزيم حزمة الجوال (Android + iOS)
# -------------------------
print("\n=== الخطوة 3: تحزيم حزمة الجوال (Android + iOS) ===")
mobile_zip = os.path.join(OUTPUT_DIR, "tadabur-whisper-mobile.zip")

with zipfile.ZipFile(mobile_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
    zf.write(encoder_int8, "encoder.int8.onnx")
    zf.write(decoder_int8, "decoder.int8.onnx")
    zf.write(tokens_path, "tokens.txt")
    # ملفات الإعداد
    for cfg_file in ["config.json", "generation_config.json", "preprocessor_config.json"]:
        cfg_path = os.path.join(ONNX_DIR, cfg_file)
        if os.path.exists(cfg_path):
            zf.write(cfg_path, cfg_file)

print(f"  tadabur-whisper-mobile.zip -> {file_size_mb(mobile_zip):.0f} MB")

# -------------------------
# الخطوة 4: تحزيم حزمة الويندوز / سطح المكتب
# -------------------------
print("\n=== الخطوة 4: تحزيم حزمة الويندوز / Desktop ===")
desktop_zip = os.path.join(OUTPUT_DIR, "tadabur-whisper-desktop.zip")

with zipfile.ZipFile(desktop_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
    zf.write(ENCODER_SRC, "encoder_model.onnx")
    zf.write(DECODER_SRC, "decoder_model.onnx")
    zf.write(tokens_path, "tokens.txt")
    for cfg_file in ["config.json", "generation_config.json", "preprocessor_config.json"]:
        cfg_path = os.path.join(ONNX_DIR, cfg_file)
        if os.path.exists(cfg_path):
            zf.write(cfg_path, cfg_file)

print(f"  tadabur-whisper-desktop.zip -> {file_size_mb(desktop_zip):.0f} MB")

# -------------------------
# الملخص النهائي
# -------------------------
print("\n" + "="*50)
print("تم التحضير بنجاح! الملفات الجاهزة للرفع:")
print("="*50)
for fname in os.listdir(OUTPUT_DIR):
    fpath = os.path.join(OUTPUT_DIR, fname)
    if os.path.isfile(fpath):
        print(f"  {fname}  ({file_size_mb(fpath):.1f} MB)")
print("\nارفعها على GitHub Releases تحت:")
print("  Tag: v1.0.0-tadabur-model")
print("="*50)
