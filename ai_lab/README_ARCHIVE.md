# أرشيف نموذج تدبر القرآني (Tadabbur Whisper Archive)

> **الغرض من هذا الفرع (`archive/tadabbur-model`):**
> توثيق وحفظ كامل الأكواد والسكربتات والأدوات الخاصة بنموذج "تدبر" القديم المبني على Whisper مع Sherpa-ONNX، تحسباً للحاجة إليها مستقبلاً.

---

## 📌 نبذة عن النموذج والمعمارية
* **النموذج:** `Whisper-Small-Arabic-Tadabbur` مكمم بصيغة INT8.
* **المحرك المستخدم:** `sherpa-onnx` نمط Offline Recognizer (Non-streaming).
* **الملفات المستهدفة:**
  - `encoder.int8.onnx`
  - `decoder.int8.onnx`
  - `tokens.txt`

---

## 🛠️ محتويات هذا الأرشيف من السكربتات

1. **سكربتات إصلاح الـ Metadata:**
   - [fix_tadabbur_model.py](file:///c:/Projects/mathani/fix_tadabbur_model.py): حقن الـ Metadata المطلوبة لـ Sherpa-ONNX داخل ملفات ONNX.
   - [patch_tadabbur_v2.py](file:///c:/Projects/mathani/patch_tadabbur_v2.py): تعديل الـ graph وأبعاد الدخل.
   - [patch_tadabbur_v3.py](file:///c:/Projects/mathani/patch_tadabbur_v3.py): إصلاح مشكلة decode loops و beam search.

2. **سكربتات التحويل والتصدير (`ai_lab/`):**
   - [export_tadabur_sherpa.py](file:///c:/Projects/mathani/ai_lab/export_tadabur_sherpa.py): تصدير النموذج من HuggingFace إلى صيغة Sherpa ONNX.
   - [hf_to_whisper_small.py](file:///c:/Projects/mathani/ai_lab/hf_to_whisper_small.py): تحويل أوزان Hugging Face الأصلية.
   - [tadabur_to_sherpa.py](file:///c:/Projects/mathani/ai_lab/tadabur_to_sherpa.py): تهيئة قاموس الرموز والترميز الصوتي.
   - [prepare_release.py](file:///c:/Projects/mathani/ai_lab/prepare_release.py): ضغط وتجهيز حزم الإصدار للموبايل والديسكتوب.

3. **أدوات الاختبار المعملي:**
   - [live_test.py](file:///c:/Projects/mathani/ai_lab/live_test.py): اختبار التعرف المباشر.
   - [mic_test.py](file:///c:/Projects/mathani/ai_lab/mic_test.py): اختبار التقاط الصوت من الميكروفون.
   - [web_test.py](file:///c:/Projects/mathani/ai_lab/web_test.py): واجهة ويب تجريبية خفيفة.

---

## ⚠️ ملاحظة بخصوص ملفات الأوزان الكبيرة (.onnx و .zip)
نظراً لحدود GitHub (التي تمنع رفع ملفات أكبر من 100 ميجابايت في مستودع الكود):
* تم استثناء الحزم الثنائية المضغوطة (`tadabur-whisper-mobile.zip` و `tadabur-whisper-desktop.zip`) من هذا الفرع.
* ملفات الأوزان محفوظة ومتاحة للتحميل عبر إصدارات GitHub Releases للتطبيق.
