import os
import sys
import json
import shutil
import zipfile

# reconfigure stdout/stderr for safe printing of unicode in windows
if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

# ----------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------
MODEL_DIR = r"C:\Users\Abdussalam\AppData\Roaming\com.example\mathani\ai_models\asr"
ENCODER_FILE = os.path.join(MODEL_DIR, "encoder.int8.onnx")
DECODER_FILE = os.path.join(MODEL_DIR, "decoder.int8.onnx")

ONNX_MODEL_SRC_DIR = r"c:\Projects\mathani\ai_lab\onnx_model"
CONFIG_FILE = os.path.join(ONNX_MODEL_SRC_DIR, "config.json")
GEN_CONFIG_FILE = os.path.join(ONNX_MODEL_SRC_DIR, "generation_config.json")

def main():
    print("=" * 60)
    print("  إصلاح نموذج تدبر-Whisper وكتابة الـ Metadata الصحيحة بالكامل  ")
    print("=" * 60)

    # 1. التحقق من وجود المكتبات والملفات
    try:
        import onnx
    except ImportError:
        print("❌ مكتبة onnx غير مثبتة. الرجاء تشغيل: pip install onnx")
        return

    try:
        from transformers import WhisperTokenizer
    except ImportError:
        print("❌ مكتبة transformers غير مثبتة. الرجاء تشغيل: pip install transformers")
        return

    if not os.path.exists(ENCODER_FILE) or not os.path.exists(DECODER_FILE):
        print(f"❌ ملفات النموذج غير موجودة في مجلد التطبيق: {MODEL_DIR}")
        return

    if not os.path.exists(CONFIG_FILE) or not os.path.exists(GEN_CONFIG_FILE):
        print(f"❌ ملفات إعداد النموذج غير موجودة في: {ONNX_MODEL_SRC_DIR}")
        return

    # 2. تحميل Tokenizer والملفات الإعدادية
    print("\n[1/5] تحميل الـ Tokenizer وإعدادات النموذج...")
    tokenizer = WhisperTokenizer.from_pretrained(ONNX_MODEL_SRC_DIR)
    
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        config = json.load(f)
        
    with open(GEN_CONFIG_FILE, 'r', encoding='utf-8') as f:
        gen_config = json.load(f)

    # 3. حساب وتوليد الملف الكامل tokens.txt
    print("\n[2/5] توليد ملف tokens.txt الكامل (51865 رمزاً)...")
    tokens_file_path = os.path.join(MODEL_DIR, "tokens.txt")
    
    # حفظ نسخة احتياطية من tokens.txt القديم
    if os.path.exists(tokens_file_path) and not os.path.exists(tokens_file_path + ".backup"):
        shutil.copy2(tokens_file_path, tokens_file_path + ".backup")
        print("   💾 تم إنشاء نسخة احتياطية لـ tokens.txt")

    with open(tokens_file_path, "w", encoding="utf-8") as f:
        for i in range(51865):
            token = tokenizer.convert_ids_to_tokens(i)
            # استبدال المسافات العادية بمسافة BPE إذا لزم الأمر، لكن Whisper يستخدم Ġ
            f.write(f"{token} {i}\n")
    print(f"   ✓ تم حفظ {tokens_file_path} بنجاح.")

    # 4. حساب الـ non_speech_tokens والـ metadata بالكامل
    print("\n[3/5] حساب الـ non_speech_tokens والـ metadata...")
    
    symbols = list('"#()*+/:;<=>@[\\]^_`{|}~「」『』')
    symbols += "<< >> <<< >>> -- --- -( -[ (' (\" (( )) ((( ))) [[ ]] {{ }} ♪♪ ♪♪♪".split()
    miscellaneous = set("♩♪♫♬♭♮♯")

    # استخراج non_speech_tokens بنفس خوارزمية OpenAI
    result_tokens = {
        tokenizer.encode(" -", add_special_tokens=False)[0],
        tokenizer.encode(" '", add_special_tokens=False)[0]
    }
    for symbol in symbols + list(miscellaneous):
        for tokens in [
            tokenizer.encode(symbol, add_special_tokens=False),
            tokenizer.encode(" " + symbol, add_special_tokens=False),
        ]:
            if len(tokens) == 1 or symbol in miscellaneous:
                result_tokens.add(tokens[0])

    non_speech_tokens_str = ",".join(map(str, sorted(result_tokens)))
    
    # إعداد قائمة اللغات
    lang_to_id = gen_config.get("lang_to_id", {})
    all_language_tokens_list = []
    all_language_codes_list = []
    for lang_tag, lang_id in lang_to_id.items():
        all_language_tokens_list.append(str(lang_id))
        # تنظيف رمز اللغة (مثال: <|ar|> -> ar)
        clean_code = lang_tag.replace("<|", "").replace("|>", "")
        all_language_codes_list.append(clean_code)

    all_language_tokens_str = ",".join(all_language_tokens_list)
    all_language_codes_str = ",".join(all_language_codes_list)

    # قيم الرموز الخاصة
    sot = gen_config.get("decoder_start_token_id", 50258)
    eot = gen_config.get("eos_token_id", 50257)
    blank_id = tokenizer.encode(" ", add_special_tokens=False)[0]
    no_speech = gen_config.get("no_timestamps_token_id", 50363) - 1 # 50362
    transcribe = gen_config.get("task_to_id", {}).get("transcribe", 50359)
    translate = gen_config.get("task_to_id", {}).get("translate", 50358)
    sot_prev = gen_config.get("prev_sot_token_id", 50361)
    sot_lm = sot_prev - 1 # 50360
    no_timestamps = gen_config.get("no_timestamps_token_id", 50363)
    
    # تحديد رمز اللغة المستهدفة (العربية: 50272)
    lang_id = lang_to_id.get("<|ar|>", 50272)
    
    # ترتيب sot_sequence: start_of_transcript, language, task, no_timestamps
    sot_sequence_str = f"{sot},{lang_id},{transcribe},{no_timestamps}"

    # الـ metadata الكاملة المتوافقة مع Whisper Small
    metadata = {
        "model_type": "whisper-small",
        "version": "1",
        "maintainer": "k2-fsa",
        "n_mels": str(config.get("num_mel_bins", 80)),
        "n_audio_ctx": str(config.get("max_source_positions", 1500)),
        "n_audio_state": str(config.get("d_model", 768)),
        "n_audio_head": str(config.get("encoder_attention_heads", 12)),
        "n_audio_layer": str(config.get("encoder_layers", 12)),
        "n_vocab": str(config.get("vocab_size", 51865)),
        "n_text_ctx": str(config.get("max_target_positions", 448)),
        "n_text_state": str(config.get("d_model", 768)),
        "n_text_head": str(config.get("decoder_attention_heads", 12)),
        "n_text_layer": str(config.get("decoder_layers", 12)),
        "sot_sequence": sot_sequence_str,
        "all_language_tokens": all_language_tokens_str,
        "all_language_codes": all_language_codes_str,
        "sot": str(sot),
        "sot_index": "0",
        "eot": str(eot),
        "blank_id": str(blank_id),
        "is_multilingual": "1" if gen_config.get("is_multilingual", True) else "0",
        "no_speech": str(no_speech),
        "non_speech_tokens": non_speech_tokens_str,
        "transcribe": str(transcribe),
        "translate": str(translate),
        "sot_prev": str(sot_prev),
        "sot_lm": str(sot_lm),
        "no_timestamps": str(no_timestamps),
    }

    # 5. كتابة الـ metadata في ملفات ONNX
    print("\n[4/5] كتابة الـ Metadata لملفات الـ ONNX...")
    
    def patch_file(file_path):
        if not os.path.exists(file_path):
            print(f"   ⚠️ ملف غير موجود لتعديله: {file_path}")
            return
        
        # حفظ نسخة احتياطية
        backup_path = file_path + ".backup"
        if not os.path.exists(backup_path):
            shutil.copy2(file_path, backup_path)
            print(f"   💾 نسخة احتياطية لـ {os.path.basename(file_path)}")
            
        model = onnx.load(file_path)
        
        # مسح الـ metadata القديمة
        while len(model.metadata_props):
            model.metadata_props.pop()
            
        # إضافة الجديدة
        for k, v in metadata.items():
            meta = model.metadata_props.add()
            meta.key = k
            meta.value = v
            
        onnx.save(model, file_path)
        print(f"   ✅ تم تعديل وحفظ {os.path.basename(file_path)}")

    patch_file(ENCODER_FILE)
    patch_file(DECODER_FILE)

    # 6. ضغط وتحديث ملف zip
    print("\n[5/5] إنشاء ملف zip الجديد (tadabur-whisper-mobile.zip) لرفعه على GitHub...")
    zip_output_path = os.path.join(r"c:\Projects\mathani", "tadabur-whisper-mobile.zip")
    
    files_to_zip = [
        ("encoder.int8.onnx", ENCODER_FILE),
        ("decoder.int8.onnx", DECODER_FILE),
        ("tokens.txt", tokens_file_path),
        ("config.json", CONFIG_FILE),
        ("generation_config.json", GEN_CONFIG_FILE),
        ("preprocessor_config.json", os.path.join(ONNX_MODEL_SRC_DIR, "preprocessor_config.json")),
    ]
    
    with zipfile.ZipFile(zip_output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for arcname, filepath in files_to_zip:
            if os.path.exists(filepath):
                zipf.write(filepath, arcname)
                print(f"   + إضافة {arcname}")
            else:
                print(f"   ⚠️ ملف مفقود ولم يُضاف للـ zip: {arcname}")
                
    zip_size_mb = os.path.getsize(zip_output_path) / 1024 / 1024
    print("\n" + "=" * 60)
    print("🎉 تم الإصلاح والتحزيم بنجاح!")
    print(f"   الموديلات المحلية في التطبيق: تم إصلاحها وتحديثها ✓")
    print(f"   الملف المضغوط للرفع: {zip_output_path} ({zip_size_mb:.2f} MB)")
    print("=" * 60)

if __name__ == "__main__":
    main()
