"""
إصلاح نموذج تدبر-Whisper لتوافق Sherpa-ONNX

المشكلة: الملفات encoder.int8.onnx و decoder.int8.onnx
         تفتقر لـ metadata مطلوبة من Sherpa-ONNX.

الحل: إضافة الـ metadata مباشرة داخل الملفات.

المتطلبات:
    pip install onnx

الاستخدام:
    python fix_tadabbur_model.py
"""

import os
import sys

# تهيئة ترميز الكونسول لتفادي الأخطاء في ويندوز
if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

# ──────────────────────────────────────────────────────────
# مسار النموذج (تعديل إذا كان مختلفاً عندك)
# ──────────────────────────────────────────────────────────
MODEL_DIR = r"C:\Users\Abdussalam\AppData\Roaming\com.example\mathani\ai_models\asr"
ENCODER_FILE = os.path.join(MODEL_DIR, "encoder.int8.onnx")
DECODER_FILE = os.path.join(MODEL_DIR, "decoder.int8.onnx")

# ──────────────────────────────────────────────────────────
# Metadata مطلوبة (لنموذج Whisper Medium متعدد اللغات)
# ──────────────────────────────────────────────────────────
ENCODER_METADATA = {
    "n_mels":        "80",    # عدد قنوات Mel Filterbank
    "n_audio_ctx":   "1500",  # طول السياق الصوتي
    "n_audio_state": "1024",  # حجم حالة الـ Encoder
    "n_audio_head":  "16",    # عدد رؤوس الانتباه
    "n_audio_layer": "24",    # عدد الطبقات
}

DECODER_METADATA = {
    "n_vocab":      "51864",  # حجم قاموس الرموز
    "n_text_ctx":   "448",    # طول سياق النص
    "n_text_state": "1024",   # حجم حالة الـ Decoder
    "n_text_head":  "16",     # عدد رؤوس الانتباه
    "n_text_layer": "24",     # عدد الطبقات
}


def patch_model(file_path: str, metadata: dict) -> bool:
    """إضافة metadata لملف ONNX"""
    try:
        import onnx
    except ImportError:
        print("❌ مكتبة onnx غير مثبتة. شغّل:")
        print("   pip install onnx")
        sys.exit(1)

    if not os.path.exists(file_path):
        print(f"❌ الملف غير موجود: {file_path}")
        return False

    file_size_mb = os.path.getsize(file_path) / 1024 / 1024
    print(f"\n📂 تحميل: {os.path.basename(file_path)} ({file_size_mb:.1f} MB)")

    # تحقق من الـ metadata الموجودة
    model = onnx.load(file_path)
    existing_keys = {prop.key for prop in model.metadata_props}
    print(f"   Metadata موجودة: {existing_keys if existing_keys else 'لا شيء'}")

    # إضافة الـ metadata الناقصة فقط
    added = []
    for key, value in metadata.items():
        if key not in existing_keys:
            meta = model.metadata_props.add()
            meta.key = key
            meta.value = value
            added.append(f"{key}={value}")
        else:
            print(f"   ⏭ {key} موجود مسبقاً")

    if added:
        print(f"   ✅ إضافة: {', '.join(added)}")
        # حفظ النسخة المُصلحة
        backup_path = file_path + ".backup"
        if not os.path.exists(backup_path):
            import shutil
            shutil.copy2(file_path, backup_path)
            print(f"   💾 نسخة احتياطية: {os.path.basename(backup_path)}")
        onnx.save(model, file_path)
        print(f"   ✅ تم الحفظ بنجاح")
    else:
        print(f"   ℹ️ الـ metadata مكتملة مسبقاً")

    return True


def verify_model(file_path: str, required_keys: list) -> bool:
    """التحقق من صحة الـ metadata بعد الإصلاح"""
    import onnx
    model = onnx.load(file_path)
    existing = {p.key: p.value for p in model.metadata_props}
    all_ok = True
    for key in required_keys:
        if key in existing:
            print(f"   ✅ {key} = {existing[key]}")
        else:
            print(f"   ❌ {key} مفقود!")
            all_ok = False
    return all_ok


def main():
    print("=" * 55)
    print("  إصلاح نموذج تدبر-Whisper لتوافق Sherpa-ONNX  ")
    print("=" * 55)

    # ─── إصلاح Encoder ───
    print("\n[ 1/2 ] إصلاح Encoder ...")
    patch_model(ENCODER_FILE, ENCODER_METADATA)

    # ─── إصلاح Decoder ───
    print("\n[ 2/2 ] إصلاح Decoder ...")
    patch_model(DECODER_FILE, DECODER_METADATA)

    # ─── التحقق النهائي ───
    print("\n" + "=" * 55)
    print("  التحقق من النتائج  ")
    print("=" * 55)

    print(f"\n🔍 Encoder metadata:")
    enc_ok = verify_model(ENCODER_FILE, list(ENCODER_METADATA.keys()))

    print(f"\n🔍 Decoder metadata:")
    dec_ok = verify_model(DECODER_FILE, list(DECODER_METADATA.keys()))

    print("\n" + "=" * 55)
    if enc_ok and dec_ok:
        print("✅ الإصلاح مكتمل! شغّل التطبيق من جديد.")
        print("   إذا عمل Sherpa-ONNX سترى الرسالة التالية في Logs:")
        print("   '✅ OfflineRecognizer created successfully'")
    else:
        print("❌ بعض الحقول ما زالت ناقصة — راجع الأخطاء أعلاه.")
    print("=" * 55)


if __name__ == "__main__":
    main()
