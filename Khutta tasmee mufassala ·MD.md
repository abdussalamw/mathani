# خطة تنفيذية مفصلة — قسم التسميع الذكي في مثاني
## دليل خطوة بخطوة لمبرمج مبتدئ

---

> **ملاحظة قبل البدء:** هذا الملف مكتوب بأقصى تفصيل ممكن. لا تتخطَّ أي خطوة حتى لو بدت واضحة. كل خطوة تحتوي على: ماذا نفعل، لماذا نفعله، كيف نتحقق أنه نجح.

---

## الفهرس

1. [نظرة عامة على المشروع](#نظرة-عامة)
2. [المرحلة صفر: تجهيز البيئة](#المرحلة-صفر)
3. [المرحلة واحد: الحصول على النموذج وتحويله](#المرحلة-واحد)
4. [المرحلة اثنان: التحقق من النموذج المُحوَّل](#المرحلة-اثنان)
5. [المرحلة ثلاثة: إعداد مشروع Flutter](#المرحلة-ثلاثة)
6. [المرحلة أربعة: بناء واجهة المستخدم بدون نماذج حقيقية](#المرحلة-أربعة)
7. [المرحلة خمسة: دمج النموذج الحقيقي](#المرحلة-خمسة)
8. [المرحلة ستة: مطابقة النص بالمصحف](#المرحلة-ستة)
9. [المرحلة سبعة: الاختبار الشامل](#المرحلة-سبعة)
10. [ملحق: حل المشاكل الشائعة](#ملحق-المشاكل)

---

<a name="نظرة-عامة"></a>
## ١. نظرة عامة على المشروع

### ماذا نبني بالضبط؟

ميزة داخل تطبيق مثاني تسمح للمستخدم أن:
1. يفتح صفحة "التسميع"
2. يختار سورة أو نطاق آيات
3. يضغط زر التسجيل ويقرأ
4. يضغط "انتهيت"
5. يرى النتيجة: كل كلمة ملوّنة (أخضر = صحيحة، أحمر = خطأ، رمادي = لم تُقرأ)

### ما الذي **لا** نبنيه في هذه المرحلة (V1)؟

- ❌ تقييم التجويد (مد، غنة، إدغام) — هذا V2 لاحقاً
- ❌ اتصال بالإنترنت من أي نوع
- ❌ أي اشتراك أو دفع

### المكونات التقنية الثلاثة

```
١- نموذج ASR (يحوّل الصوت لنص)      → Tadabur-Whisper-Small
٢- منطق المطابقة (يقارن النص بالمصحف) → كود Dart نكتبه نحن
٣- واجهة المستخدم (يعرض النتيجة)      → Flutter widgets
```

---

<a name="المرحلة-صفر"></a>
## ٢. المرحلة صفر: تجهيز البيئة

### الهدف من هذه المرحلة
التأكد أن كل الأدوات التي نحتاجها مثبتة وتعمل، قبل أن نكتب أي كود.

### الخطوة 0.1 — تأكد من تثبيت Flutter

**ماذا نفعل:**
افتح Terminal أو PowerShell واكتب:
```bash
flutter --version
```

**ماذا يجب أن تراه:**
```
Flutter 3.x.x • channel stable
```

**إذا ظهر خطأ "command not found":**
Flutter غير مثبت. اذهب إلى `https://docs.flutter.dev/get-started/install` واتبع التعليمات لنظام تشغيلك (Windows/Mac/Linux).

**كيف تتحقق أن هذه الخطوة نجحت:**
الأمر يطبع رقم إصدار Flutter بدون أي رسالة خطأ حمراء.

---

### الخطوة 0.2 — تأكد من وجود مشروع مثاني

**ماذا نفعل:**
```bash
cd path/to/mathani
flutter doctor
```

**ماذا يجب أن تراه:**
قائمة بعلامات ✓ خضراء لكل من: Flutter, Android toolchain, (Xcode إذا كنت على Mac).

**إذا ظهرت علامة ✗ حمراء:**
اقرأ الرسالة بعناية — عادة تخبرك بالضبط ماذا ينقصك (مثل: "Android licenses not accepted" → شغّل `flutter doctor --android-licenses`).

---

### الخطوة 0.3 — ثبّت Python (للتحويل لاحقاً)

**ماذا نفعل:**
```bash
python --version
```

**ماذا يجب أن تراه:**
```
Python 3.10.x أو أحدث
```

**إذا لم يكن مثبتاً:**
حمّله من `https://www.python.org/downloads/` — عند التثبيت على Windows، **تأكد من تفعيل خيار "Add Python to PATH"**.

---

### الخطوة 0.4 — أنشئ حساب HuggingFace (إذا لم يكن موجوداً)

**لماذا نحتاجه:**
لتحميل نموذج Tadabur.

**ماذا نفعل:**
1. اذهب إلى `https://huggingface.co/join`
2. أنشئ حساباً بإيميلك
3. فعّل الإيميل من الرسالة المرسلة

**كيف تتحقق:**
تستطيع تسجيل الدخول في `https://huggingface.co`

---

### الخطوة 0.5 — أنشئ Access Token

**ماذا نفعل:**
1. اذهب إلى `https://huggingface.co/settings/tokens`
2. اضغط **"New token"**
3. اسم التوكن: `mathani-download`
4. النوع: **Read** فقط (وليس Write أو Admin)
5. اضغط **"Create token"**
6. **انسخ التوكن فوراً واحفظه في مكان آمن** (لن يظهر لك مرة أخرى كاملاً)

**تحذير أمني مهم:**
لا تشارك هذا التوكن مع أي أحد، ولا تكتبه في أي كود سترفعه على GitHub علناً.

**كيف تتحقق:**
التوكن يبدأ بـ `hf_` ويتكون من حروف وأرقام عشوائية.

---

<a name="المرحلة-واحد"></a>
## ٣. المرحلة واحد: الحصول على النموذج وتحويله

### الهدف من هذه المرحلة
تحميل نموذج Tadabur وتحويله لصيغة يمكن لـ Flutter استخدامها (ONNX).

### لماذا نحتاج "تحويل" أصلاً؟

النموذج الأصلي محفوظ بصيغة PyTorch (`.bin` أو `.safetensors`) — وهذه الصيغة **لا تعمل مباشرة على الهاتف**. نحتاج تحويله لصيغة ONNX التي تدعمها مكتبات الهاتف.

---

### الخطوة 1.1 — أنشئ مجلد العمل

**ماذا نفعل:**
```bash
mkdir C:\Projects\mathani\model
cd C:\Projects\mathani\model
```

**ملاحظة مهمة:** تجنب الأحرف العربية أو المسافات في أسماء المجلدات — بعض أدوات Python تفشل معها.

**كيف تتحقق:**
```bash
dir
```
يجب أن يظهر المجلد فارغاً (أو قائمة الملفات الحالية إن وُجدت).

---

### الخطوة 1.2 — ثبّت مكتبة huggingface_hub

**ماذا نفعل:**
```bash
pip install huggingface_hub
```

**ماذا يجب أن تراه:**
```
Successfully installed huggingface_hub-x.x.x
```

**كيف تتحقق:**
```bash
hf --help
```
يجب أن تظهر قائمة أوامر بدون خطأ.

---

### الخطوة 1.3 — حمّل نموذج Tadabur الأصلي

**ماذا نفعل:**
```bash
hf download FaisaI/tadabur-Whisper-Small --local-dir "C:\Projects\mathani\tadabur" --token "hf_التوكن_الذي_نسخته"
```

**ماذا يحدث:**
سيبدأ تحميل ملفات بحجم إجمالي حوالي 970 ميجابايت. قد يأخذ 5-15 دقيقة حسب سرعة الإنترنت.

**ماذا يجب أن تراه في النهاية:**
```
Download complete: 100%
✓ Downloaded
  path: C:\Projects\mathani\tadabur
```

**كيف تتحقق أن هذه الخطوة نجحت:**
```bash
dir "C:\Projects\mathani\tadabur"
```
يجب أن ترى 19 ملفاً تقريباً، أهمها:
```
model.safetensors    (حوالي 967 MB)
config.json
vocab.json
tokenizer.json
added_tokens.json
```

**إذا فشل التحميل بخطأ "Invalid user token":**
- تأكد أنك نسخت التوكن كاملاً بدون مسافات زائدة
- جرّب إنشاء توكن جديد من الخطوة 0.5

---

### الخطوة 1.4 — ثبّت مكتبات التحويل

**ماذا نفعل:**
```bash
pip install torch transformers optimum onnx onnxruntime
```

**لماذا نحتاج كل مكتبة:**

| المكتبة | الوظيفة |
|---------|---------|
| `torch` | تشغيل النموذج الأصلي |
| `transformers` | قراءة نموذج Whisper |
| `optimum` | أداة التحويل لـ ONNX |
| `onnx` | صيغة الملف الناتج |
| `onnxruntime` | تشغيل واختبار ONNX |

**تحذير مهم عن تعارض الإصدارات:**
أحياناً تتعارض إصدارات هذه المكتبات مع بعضها. إذا واجهت خطأ `ImportError`، جرّب:
```bash
pip install "optimum==1.23.3" "transformers==4.46.0" --force-reinstall
```

**كيف تتحقق:**
```bash
python -c "import torch; import transformers; import optimum; print('كل شيء يعمل')"
```

---

### الخطوة 1.5 — افتح Google Colab (الطريقة الموصى بها)

**لماذا Colab وليس جهازك؟**
بيئة Colab نظيفة تماماً بدون تعارضات إصدارات قد تكون موجودة على جهازك من مشاريع سابقة.

**ماذا نفعل:**
1. اذهب إلى `https://colab.research.google.com`
2. سجّل دخولك بحساب Google
3. اضغط **File → New notebook**

---

### الخطوة 1.6 — اكتب كود التحويل في Colab

**ماذا نفعل:**
انسخ هذا الكود في خلية أولى واضغط ▶ (Run):

```python
# الخلية 1: تثبيت المتطلبات
!pip install -q torch transformers optimum[exporters] onnx onnxruntime
print("✅ تم التثبيت")
```

**انتظر حتى تنتهي** (رمز ▶ يتحول لدائرة دوارة ثم لعلامة ✓)

---

في خلية ثانية:

```python
# الخلية 2: تسجيل الدخول في HuggingFace
from huggingface_hub import login
HF_TOKEN = "hf_التوكن_الذي_نسخته"  # ضع توكنك هنا
login(token=HF_TOKEN)
print("✅ تم تسجيل الدخول")
```

**تحذير:** لا تشارك هذا الـ notebook مع أحد وفيه توكنك ظاهراً. احذف التوكن بعد الانتهاء أو استخدم Colab Secrets (ميزة متقدمة، اختيارية).

---

في خلية ثالثة:

```python
# الخلية 3: تحميل النموذج
from huggingface_hub import snapshot_download

model_dir = '/content/tadabur-original'
snapshot_download(
    repo_id='FaisaI/tadabur-Whisper-Small',
    local_dir=model_dir,
    token=HF_TOKEN
)
print("✅ تم تحميل النموذج")
!ls {model_dir}
```

**ماذا يجب أن تراه:**
قائمة بنفس الملفات التي رأيتها في الخطوة 1.3.

---

في خلية رابعة:

```python
# الخلية 4: التحويل الفعلي لـ ONNX
from optimum.exporters.onnx import main_export

output_dir = '/content/onnx_output'

main_export(
    model_name_or_path=model_dir,
    output=output_dir,
    task='automatic-speech-recognition',
    opset=17,
)
print("✅ تم التصدير")
!ls -lh {output_dir}/*.onnx
```

**ماذا يحدث:**
هذه الخطوة تأخذ 2-5 دقائق. تحوّل النموذج من PyTorch إلى ONNX.

**ماذا يجب أن تراه:**
```
encoder_model.onnx    (حوالي 300-400 MB قبل الضغط)
decoder_model.onnx    (حوالي 500-600 MB قبل الضغط)
```

---

في خلية خامسة:

```python
# الخلية 5: تكميم (ضغط) النماذج لتصغير الحجم
from pathlib import Path
from onnxruntime.quantization import QuantType, quantize_dynamic

output_path = Path(output_dir)

# ضغط encoder
encoder_src = output_path / 'encoder_model.onnx'
encoder_dst = output_path / 'encoder.int8.onnx'
quantize_dynamic(
    model_input=str(encoder_src),
    model_output=str(encoder_dst),
    op_types_to_quantize=['MatMul'],
    weight_type=QuantType.QInt8,
)
print(f"✅ encoder.int8.onnx: {encoder_dst.stat().st_size/1024/1024:.1f} MB")

# ضغط decoder
decoder_src = output_path / 'decoder_model.onnx'
decoder_dst = output_path / 'decoder.int8.onnx'
quantize_dynamic(
    model_input=str(decoder_src),
    model_output=str(decoder_dst),
    op_types_to_quantize=['MatMul'],
    weight_type=QuantType.QInt8,
)
print(f"✅ decoder.int8.onnx: {decoder_dst.stat().st_size/1024/1024:.1f} MB")
```

**لماذا نضغط النموذج؟**
التكميم (Quantization) يحول الأرقام من دقة 32-bit إلى 8-bit — يصغّر الحجم بحوالي 4 مرات مع خسارة دقة بسيطة جداً (أقل من 1% عادة).

**ماذا يجب أن تراه:**
```
✅ encoder.int8.onnx: ~90-120 MB
✅ decoder.int8.onnx: ~150-190 MB
```

---

في خلية سادسة:

```python
# الخلية 6: استخراج ملف الرموز (tokens.txt)
import json
from pathlib import Path

vocab_file = Path(model_dir) / 'vocab.json'
added_tokens_file = Path(model_dir) / 'added_tokens.json'

with open(vocab_file, 'r', encoding='utf-8') as f:
    vocab = json.load(f)

if added_tokens_file.exists():
    with open(added_tokens_file, 'r', encoding='utf-8') as f:
        added_tokens = json.load(f)
    vocab.update(added_tokens)

tokens = sorted(vocab.items(), key=lambda x: x[1])

tokens_file = Path(output_dir) / 'tokens.txt'
with open(tokens_file, 'w', encoding='utf-8') as f:
    for token, idx in tokens:
        f.write(f'{token} {idx}\n')

print(f"✅ tokens.txt: {len(tokens)} رمز")
```

**لماذا نحتاج هذا الملف تحديداً؟**
`tokens.txt` هو "القاموس" الذي يترجم أرقام (التي ينتجها النموذج) إلى حروف عربية حقيقية. بدونه، النموذج يعطيك أرقاماً بلا معنى.

**ماذا يجب أن تراه:**
```
✅ tokens.txt: 51865 رمز
```

---

في خلية سابعة (التحقق النهائي):

```python
# الخلية 7: التحقق من وجود الملفات الثلاثة المطلوبة
from pathlib import Path

required = ['encoder.int8.onnx', 'decoder.int8.onnx', 'tokens.txt']
output_path = Path(output_dir)

print("=== نتيجة التحقق ===")
all_ok = True
for f in required:
    p = output_path / f
    if p.exists():
        size_mb = p.stat().st_size / 1024 / 1024
        print(f"✅ {f} — {size_mb:.1f} MB")
    else:
        print(f"❌ {f} — مفقود!")
        all_ok = False

if all_ok:
    print("\n🎉 كل الملفات جاهزة!")
else:
    print("\n⚠️ راجع الخطوات السابقة")
```

**ماذا يجب أن تراه:**
```
✅ encoder.int8.onnx — 95.3 MB
✅ decoder.int8.onnx — 178.2 MB
✅ tokens.txt — 0.7 MB

🎉 كل الملفات جاهزة!
```

---

### الخطوة 1.7 — حمّل الملفات الثلاثة إلى جهازك

في خلية أخيرة:

```python
# الخلية 8: ضغط وتحميل النتائج
import shutil
from google.colab import files

zip_path = '/content/mathani_onnx_models'
shutil.make_archive(zip_path, 'zip', output_dir)

print("جاري بدء التحميل...")
files.download(zip_path + '.zip')
```

**ماذا يحدث:**
سيبدأ تحميل ملف `mathani_onnx_models.zip` مباشرة على جهازك من المتصفح.

**كيف تتحقق:**
افتح مجلد التحميلات (Downloads) وستجد الملف. افتحه (فك الضغط) وتحقق من وجود الملفات الثلاثة بداخله.

---

<a name="المرحلة-اثنان"></a>
## ٤. المرحلة اثنان: التحقق من النموذج المُحوَّل

### الهدف من هذه المرحلة
التأكد أن التحويل نجح فعلياً قبل إضاعة وقت في دمجه بـ Flutter.

### الخطوة 2.1 — ثبّت مكتبة sherpa-onnx على بايثون (للاختبار فقط)

**ماذا نفعل:**
```bash
pip install sherpa-onnx
```

---

### الخطوة 2.2 — احصل على ملف صوتي لاختبار

**ماذا نفعل:**
سجّل نفسك تقرأ آية قصيرة (مثل سورة الإخلاص) وحفظها كـ WAV بمعدل 16000Hz.

**كيف تسجل بهذا المعدل بسهولة:**
استخدم أي تطبيق تسجيل، ثم حوّله باستخدام:
```bash
pip install pydub
python -c "
from pydub import AudioSegment
sound = AudioSegment.from_file('تسجيلي.mp3')
sound = sound.set_frame_rate(16000).set_channels(1)
sound.export('test_ayah.wav', format='wav')
"
```

---

### الخطوة 2.3 — اختبر النموذج

**ماذا نفعل:**
أنشئ ملف `test_model.py`:

```python
import sherpa_onnx

recognizer = sherpa_onnx.OfflineRecognizer.from_whisper(
    encoder="encoder.int8.onnx",
    decoder="decoder.int8.onnx",
    tokens="tokens.txt",
    language="ar",
)

stream = recognizer.create_stream()
stream.accept_wave_file("test_ayah.wav")
recognizer.decode_stream(stream)

print("النص الناتج:", stream.result.text)
```

شغّله:
```bash
python test_model.py
```

**ماذا يجب أن تراه:**
```
النص الناتج: قل هو الله أحد الله الصمد
```
(أو نص عربي منطقي يطابق ما قرأته)

**إذا ظهر نص غريب أو فارغ:**
هذا يعني وجود مشكلة في التحويل. راجع الملحق في نهاية هذا الدليل.

**✅ نقطة تحقق حاسمة:** لا تنتقل للمرحلة التالية إلا بعد نجاح هذا الاختبار.

---

<a name="المرحلة-ثلاثة"></a>
## ٥. المرحلة ثلاثة: إعداد مشروع Flutter

### الهدف من هذه المرحلة
تجهيز بنية الملفات والحزم داخل مشروع مثاني.

### الخطوة 3.1 — أضف الحزم المطلوبة

**ماذا نفعل:**
افتح ملف `pubspec.yaml` في جذر المشروع وأضف تحت `dependencies:`

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... الحزم الموجودة مسبقاً تبقى كما هي

  # حزم جديدة للتسميع
  record: ^5.0.0
  sherpa_onnx: ^1.10.0
  string_similarity: ^2.0.0
  path_provider: ^2.1.0
  permission_handler: ^11.0.0
```

**لماذا كل حزمة:**

| الحزمة | الوظيفة |
|--------|---------|
| `record` | تسجيل الصوت من الميكروفون |
| `sherpa_onnx` | تشغيل نموذج Whisper محلياً |
| `string_similarity` | مقارنة النصوص (لمطابقة الآيات) |
| `path_provider` | معرفة مسارات حفظ الملفات على الهاتف |
| `permission_handler` | طلب إذن الميكروفون |

---

### الخطوة 3.2 — نزّل الحزم

**ماذا نفعل:**
```bash
flutter pub get
```

**ماذا يجب أن تراه:**
```
Got dependencies!
```

**إذا ظهر خطأ "version solving failed":**
قد يكون هناك تعارض إصدارات مع حزمة موجودة مسبقاً. جرّب حذف رقم الإصدار المحدد واستبداله بـ `any`:
```yaml
sherpa_onnx: any
```

---

### الخطوة 3.3 — أنشئ بنية المجلدات

**ماذا نفعل:**
داخل مجلد `lib/`، أنشئ هذه المجلدات والملفات الفارغة:

```bash
mkdir -p lib/data/models
mkdir -p lib/data/services
mkdir -p lib/presentation/screens/recitation
mkdir -p lib/presentation/providers
mkdir -p lib/presentation/widgets

touch lib/data/models/recitation_session.dart
touch lib/data/models/recitation_result.dart
touch lib/data/services/asr_service.dart
touch lib/data/services/audio_recorder_service.dart
touch lib/data/services/text_matching_service.dart
touch lib/presentation/providers/recitation_provider.dart
touch lib/presentation/screens/recitation/recitation_screen.dart
touch lib/presentation/screens/recitation/recitation_setup_view.dart
touch lib/presentation/screens/recitation/recitation_recording_view.dart
touch lib/presentation/screens/recitation/recitation_result_view.dart
touch lib/presentation/widgets/tajweed_word_chip.dart
```

**ملاحظة لمستخدمي Windows:**
أمر `touch` قد لا يعمل في PowerShell عادي. استخدم بدلاً منه:
```powershell
New-Item -ItemType File -Path "lib\data\models\recitation_session.dart"
```
أو ببساطة أنشئ الملفات يدوياً من داخل VS Code / Android Studio بالضغط اليمين → New File.

**كيف تتحقق:**
```bash
flutter analyze
```
لن يظهر خطأ لأن الملفات فارغة (لكن يجب ألا يظهر خطأ "file not found").

---

### الخطوة 3.4 — ضع ملفات النموذج في المشروع

**ماذا نفعل:**
1. أنشئ مجلد: `assets/models/`
2. انسخ الملفات الثلاثة إليه:
```
assets/models/encoder.int8.onnx
assets/models/decoder.int8.onnx
assets/models/tokens.txt
```

**تحذير حجم مهم:**
هذه الملفات كبيرة (~270MB مجتمعة). إذا كنت تستخدم Git، **لا** تضفها للـ commit مباشرة — استخدم Git LFS أو أضفها لـ `.gitignore` مؤقتاً وارفعها كـ GitHub Release بدلاً من ذلك (كما فعلت سابقاً).

**ماذا نفعل في pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/models/tokens.txt
    # لا تضف ملفات onnx هنا الآن - سنحملها ديناميكياً لاحقاً لتقليل حجم التطبيق
```

**لماذا لا نضيف ملفات ONNX كـ assets مباشرة؟**
إضافتها كـ assets تزيد حجم تطبيق مثاني بـ 270MB منذ اليوم الأول للتثبيت. الأفضل: تحميلها عند أول استخدام لميزة التسميع (سنبنيها لاحقاً). **لكن للتجربة والتطوير الآن، ضعها كـ assets مؤقتاً لتسهيل الاختبار:**

```yaml
flutter:
  assets:
    - assets/models/encoder.int8.onnx
    - assets/models/decoder.int8.onnx
    - assets/models/tokens.txt
```

---

<a name="المرحلة-أربعة"></a>
## ٦. المرحلة أربعة: بناء واجهة المستخدم بدون نماذج حقيقية

### الهدف من هذه المرحلة
بناء الشاشات والتفاعل البصري أولاً، باستخدام بيانات وهمية، قبل تعقيد الأمور بالنموذج الحقيقي.

### لماذا نفعل هذا بهذا الترتيب؟

إذا حاولت دمج كل شيء دفعة واحدة (واجهة + نموذج + مطابقة)، وحدث خطأ، لن تعرف مصدر المشكلة. ببناء الواجهة أولاً بـ Mock Data، تتأكد أن الجزء البصري يعمل، ثم تضيف الأجزاء الأخرى واحداً تلو الآخر.

---

### الخطوة 4.1 — عرّف نموذج البيانات الأساسي

**ماذا نفعل:**
في ملف `lib/data/models/recitation_result.dart`:

```dart
// حالة كل كلمة بعد التحليل
enum WordStatus {
  correct,    // صحيحة
  incorrect,  // خاطئة
  missing,    // لم تُقرأ
  pending,    // لم تُحلل بعد
}

// كلمة واحدة مع حالتها
class RecitationWord {
  final String text;       // نص الكلمة كما في المصحف
  final WordStatus status; // حالتها بعد التحليل

  RecitationWord({
    required this.text,
    required this.status,
  });
}

// نتيجة جلسة تسميع كاملة
class RecitationResult {
  final List<RecitationWord> words;
  final int correctCount;
  final int incorrectCount;
  final int totalCount;

  RecitationResult({
    required this.words,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalCount,
  });

  // نسبة الدقة كنسبة مئوية
  double get accuracyPercentage {
    if (totalCount == 0) return 0;
    return (correctCount / totalCount) * 100;
  }
}
```

**لماذا هذا التصميم؟**
فصل "الكلمة" عن "النتيجة الكاملة" يسهّل عرض كل كلمة بشكل منفصل في الواجهة لاحقاً.

**كيف تتحقق:**
```bash
flutter analyze lib/data/models/recitation_result.dart
```
يجب ألا يظهر أي خطأ.

---

### الخطوة 4.2 — أنشئ بيانات وهمية للاختبار

**ماذا نفعل:**
في نفس الملف أو ملف جديد `lib/data/models/mock_data.dart`:

```dart
import 'recitation_result.dart';

// بيانات وهمية لاختبار الواجهة قبل ربط النموذج الحقيقي
RecitationResult getMockRecitationResult() {
  return RecitationResult(
    words: [
      RecitationWord(text: 'بِسْمِ', status: WordStatus.correct),
      RecitationWord(text: 'اللَّهِ', status: WordStatus.correct),
      RecitationWord(text: 'الرَّحْمَٰنِ', status: WordStatus.incorrect),
      RecitationWord(text: 'الرَّحِيمِ', status: WordStatus.correct),
    ],
    correctCount: 3,
    incorrectCount: 1,
    totalCount: 4,
  );
}
```

**لماذا نفعل هذا:**
هذا يسمح لك برؤية الواجهة تعمل فوراً دون انتظار تجهيز النموذج الحقيقي بالكامل.

---

### الخطوة 4.3 — ابنِ Widget لعرض كلمة واحدة ملوّنة

**ماذا نفعل:**
في `lib/presentation/widgets/tajweed_word_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/models/recitation_result.dart';

class TajweedWordChip extends StatelessWidget {
  final RecitationWord word;

  const TajweedWordChip({super.key, required this.word});

  // نحدد اللون بناءً على حالة الكلمة
  Color _getColor() {
    switch (word.status) {
      case WordStatus.correct:
        return Colors.green.shade100;
      case WordStatus.incorrect:
        return Colors.red.shade100;
      case WordStatus.missing:
        return Colors.grey.shade300;
      case WordStatus.pending:
        return Colors.grey.shade100;
    }
  }

  Color _getBorderColor() {
    switch (word.status) {
      case WordStatus.correct:
        return Colors.green;
      case WordStatus.incorrect:
        return Colors.red;
      case WordStatus.missing:
        return Colors.grey;
      case WordStatus.pending:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor(),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        word.text,
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'Amiri', // تأكد أن هذا الخط موجود في مشروعك
        ),
      ),
    );
  }
}
```

**كيف تتحقق:**
```bash
flutter analyze lib/presentation/widgets/tajweed_word_chip.dart
```

---

### الخطوة 4.4 — ابنِ شاشة عرض النتيجة الكاملة

**ماذا نفعل:**
في `lib/presentation/screens/recitation/recitation_result_view.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/models/recitation_result.dart';
import '../../../data/models/mock_data.dart';
import '../../widgets/tajweed_word_chip.dart';

class RecitationResultView extends StatelessWidget {
  const RecitationResultView({super.key});

  @override
  Widget build(BuildContext context) {
    // مؤقتاً نستخدم البيانات الوهمية
    final result = getMockRecitationResult();

    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة التسميع')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة ملخص النتيجة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${result.accuracyPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('نسبة الدقة'),
                    const SizedBox(height: 8),
                    Text(
                      'صحيح: ${result.correctCount} / ${result.totalCount}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // الكلمات الملوّنة
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: result.words
                      .map((word) => TajweedWordChip(word: word))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**كيف تختبر هذه الشاشة فوراً:**
مؤقتاً، عدّل `lib/main.dart` لفتح هذه الشاشة مباشرة عند تشغيل التطبيق:

```dart
import 'package:flutter/material.dart';
import 'presentation/screens/recitation/recitation_result_view.dart';

void main() {
  runApp(const MyTestApp());
}

class MyTestApp extends StatelessWidget {
  const MyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RecitationResultView(),
    );
  }
}
```

شغّل:
```bash
flutter run
```

**✅ نقطة تحقق حاسمة:**
يجب أن ترى شاشة فيها نسبة دقة "75%" وأربع كلمات، إحداها بإطار أحمر (الرحمن) والباقي أخضر.

**لا تنتقل للخطوة التالية حتى ترى هذا يعمل بصرياً.**

---

<a name="المرحلة-خمسة"></a>
## ٧. المرحلة خمسة: دمج النموذج الحقيقي

### الهدف من هذه المرحلة
استبدال البيانات الوهمية بنموذج ASR حقيقي يعمل على الصوت الفعلي.

### الخطوة 5.1 — اطلب إذن الميكروفون

**ماذا نفعل:**
في `android/app/src/main/AndroidManifest.xml`، أضف قبل `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

لـ iOS، في `ios/Runner/Info.plist`، أضف:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>يحتاج مثاني إذن الميكروفون للتسميع</string>
```

---

### الخطوة 5.2 — ابنِ خدمة التسجيل

**ماذا نفعل:**
في `lib/data/services/audio_recorder_service.dart`:

```dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  // نبدأ التسجيل ونحفظه بصيغة WAV بمعدل 16000Hz (متطلب Whisper)
  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('لا يوجد إذن للميكروفون');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recitation_temp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // مهم جداً: يجب أن يطابق ما تدرب عليه النموذج
        numChannels: 1,     // صوت أحادي (mono)
      ),
      path: path,
    );
  }

  // نوقف التسجيل ونرجع مسار الملف
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
```

**لماذا معدل 16000Hz تحديداً؟**
لأن هذا هو المعدل الذي دُرّب عليه Whisper. أي معدل مختلف سيعطي نتائج خاطئة أو فارغة.

**كيف تتحقق:**
```bash
flutter analyze lib/data/services/audio_recorder_service.dart
```

---

### الخطوة 5.3 — ابنِ خدمة ASR (التعرف على الكلام)

**ماذا نفعل:**
في `lib/data/services/asr_service.dart`:

```dart
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AsrService {
  OfflineRecognizer? _recognizer;

  // ننسخ ملفات النموذج من assets لمجلد حقيقي على الهاتف
  // (sherpa_onnx يحتاج مسارات ملفات حقيقية، وليس assets مباشرة)
  Future<String> _copyAssetToFile(String assetPath, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    return file.path;
  }

  // نجهز النموذج (يُستدعى مرة واحدة عند فتح شاشة التسميع لأول مرة)
  Future<void> initialize() async {
    final encoderPath = await _copyAssetToFile(
      'assets/models/encoder.int8.onnx',
      'encoder.int8.onnx',
    );
    final decoderPath = await _copyAssetToFile(
      'assets/models/decoder.int8.onnx',
      'decoder.int8.onnx',
    );
    final tokensPath = await _copyAssetToFile(
      'assets/models/tokens.txt',
      'tokens.txt',
    );

    final config = OfflineRecognizerConfig(
      model: OfflineModelConfig(
        whisper: OfflineWhisperModelConfig(
          encoder: encoderPath,
          decoder: decoderPath,
        ),
        tokens: tokensPath,
      ),
    );

    _recognizer = OfflineRecognizer(config);
  }

  // نحلل ملف صوتي ونرجع النص
  Future<String> transcribe(String audioFilePath) async {
    if (_recognizer == null) {
      throw Exception('يجب استدعاء initialize() أولاً');
    }

    final stream = _recognizer!.createStream();
    stream.acceptWaveformFile(audioFilePath);
    _recognizer!.decode(stream);

    final result = _recognizer!.getResult(stream);
    stream.free();

    return result.text;
  }

  void dispose() {
    _recognizer?.free();
  }
}
```

**نقطة مهمة جداً — لماذا ننسخ الملفات؟**
حزمة `sherpa_onnx` (وهي مكتبة native بلغة C++) لا تستطيع قراءة الملفات مباشرة من نظام assets الخاص بـ Flutter، لذا ننسخها أولاً لمجلد حقيقي (Documents Directory) ثم نعطيها المسار الحقيقي.

**كيف تتحقق أن هذا يعمل:**
سنختبره في الخطوة التالية مع الواجهة الفعلية.

---

### الخطوة 5.4 — اربط كل شيء في شاشة التسجيل

**ماذا نفعل:**
في `lib/presentation/screens/recitation/recitation_recording_view.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/services/audio_recorder_service.dart';
import '../../../data/services/asr_service.dart';

class RecitationRecordingView extends StatefulWidget {
  const RecitationRecordingView({super.key});

  @override
  State<RecitationRecordingView> createState() =>
      _RecitationRecordingViewState();
}

class _RecitationRecordingViewState extends State<RecitationRecordingView> {
  final _recorderService = AudioRecorderService();
  final _asrService = AsrService();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isModelReady = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // تحميل النموذج عند فتح الشاشة لأول مرة
  Future<void> _loadModel() async {
    setState(() => _isProcessing = true);
    try {
      await _asrService.initialize();
      setState(() {
        _isModelReady = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('فشل تحميل النموذج: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // إيقاف التسجيل وتحليله
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      final path = await _recorderService.stopRecording();

      if (path != null) {
        final text = await _asrService.transcribe(path);
        setState(() {
          _resultText = text;
          _isProcessing = false;
        });
      }
    } else {
      // بدء التسجيل
      await _recorderService.startRecording();
      setState(() => _isRecording = true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _asrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسميع')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isModelReady)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل النموذج...'),
                ],
              )
            else ...[
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 80,
                color: _isRecording ? Colors.red : Colors.grey,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _toggleRecording,
                child: Text(_isRecording ? 'إيقاف' : 'ابدأ التسميع'),
              ),
              const SizedBox(height: 30),
              if (_isProcessing) const CircularProgressIndicator(),
              if (_resultText.isNotEmpty) ...[
                const Text('النص المتعرف عليه:'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _resultText,
                    style: const TextStyle(fontSize: 24),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
```

**كيف تختبر:**
1. عدّل `main.dart` مؤقتاً لفتح `RecitationRecordingView` بدلاً من `RecitationResultView`
2. شغّل التطبيق على **هاتف حقيقي** (المحاكي لا يدعم الميكروفون دائماً بشكل صحيح)
3. اضغط "ابدأ التسميع"، اقرأ آية قصيرة، اضغط "إيقاف"

**✅ نقطة تحقق حاسمة:**
يجب أن يظهر نص عربي منطقي يطابق ما قرأته (مثل: "قل هو الله أحد").

**إذا ظهر نص فارغ أو غريب:**
راجع قسم [حل المشاكل الشائعة](#ملحق-المشاكل) في نهاية الملف.

---

<a name="المرحلة-ستة"></a>
## ٨. المرحلة ستة: مطابقة النص بالمصحف

### الهدف من هذه المرحلة
مقارنة النص الذي أنتجه Whisper بالنص الصحيح من المصحف، وتحديد أي كلمة صحيحة وأيها خاطئة.

### الخطوة 6.1 — ابنِ خدمة المطابقة

**ماذا نفعل:**
في `lib/data/services/text_matching_service.dart`:

```dart
import '../models/recitation_result.dart';

class TextMatchingService {
  // نقارن نص المستخدم (من Whisper) بالنص الصحيح (من المصحف)
  // ونرجع نتيجة مفصلة كلمة بكلمة
  RecitationResult compare({
    required String correctText,   // النص الصحيح من قاعدة بيانات مثاني
    required String userText,      // النص الذي أنتجه Whisper
  }) {
    final correctWords = _normalizeAndSplit(correctText);
    final userWords = _normalizeAndSplit(userText);

    final List<RecitationWord> resultWords = [];
    int correctCount = 0;

    for (int i = 0; i < correctWords.length; i++) {
      final correctWord = correctWords[i];

      // هل توجد كلمة مقابلة من المستخدم في نفس الموضع؟
      if (i < userWords.length) {
        final userWord = userWords[i];

        if (_wordsMatch(correctWord, userWord)) {
          resultWords.add(RecitationWord(
            text: correctWord,
            status: WordStatus.correct,
          ));
          correctCount++;
        } else {
          resultWords.add(RecitationWord(
            text: correctWord,
            status: WordStatus.incorrect,
          ));
        }
      } else {
        // المستخدم لم يقرأ هذه الكلمة أصلاً (توقف مبكراً)
        resultWords.add(RecitationWord(
          text: correctWord,
          status: WordStatus.missing,
        ));
      }
    }

    return RecitationResult(
      words: resultWords,
      correctCount: correctCount,
      incorrectCount: correctWords.length - correctCount,
      totalCount: correctWords.length,
    );
  }

  // نزيل التشكيل والفراغات الزائدة للمقارنة العادلة
  List<String> _normalizeAndSplit(String text) {
    final normalized = text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // إزالة التشكيل
        .trim();
    return normalized.split(RegExp(r'\s+'));
  }

  // مقارنة كلمتين مع تسامح بسيط للأخطاء الإملائية الطفيفة
  bool _wordsMatch(String word1, String word2) {
    return word1 == word2;
    // ملاحظة: يمكن لاحقاً استخدام مكتبة string_similarity
    // لمقارنة أكثر تسامحاً (مثلاً: تشابه 85% فما فوق = صحيح)
  }
}
```

**لماذا نزيل التشكيل؟**
لأن Whisper عادة لا ينتج تشكيلاً كاملاً بنفس دقة المصحف، فمقارنة النص المُشكَّل بالكامل ستفشل كثيراً حتى لو كانت القراءة صحيحة.

**كيف تتحقق:**
```bash
flutter analyze lib/data/services/text_matching_service.dart
```

---

### الخطوة 6.2 — اختبر المطابقة بكود بسيط

**ماذا نفعل:**
أنشئ ملف اختبار مؤقت `lib/test_matching.dart`:

```dart
import 'data/services/text_matching_service.dart';

void main() {
  final service = TextMatchingService();

  final result = service.compare(
    correctText: 'بسم الله الرحمن الرحيم',
    userText: 'بسم الله الرحمن الرحيم',
  );

  print('نسبة الدقة: ${result.accuracyPercentage}%');
  for (final word in result.words) {
    print('${word.text}: ${word.status}');
  }
}
```

شغّله:
```bash
dart run lib/test_matching.dart
```

**ماذا يجب أن تراه:**
```
نسبة الدقة: 100.0%
بسم: WordStatus.correct
الله: WordStatus.correct
الرحمن: WordStatus.correct
الرحيم: WordStatus.correct
```

**✅ نقطة تحقق:** جرّب أيضاً بنص مختلف قليلاً وتأكد أن الكلمة المختلفة تظهر كـ `incorrect`.

---

### الخطوة 6.3 — اربط كل الأجزاء معاً

**ماذا نفعل:**
عدّل `recitation_recording_view.dart` لاستخدام `TextMatchingService` بعد الحصول على النص من Whisper، ثم انتقل لعرض `RecitationResultView` بالنتيجة الحقيقية بدلاً من المزيّفة.

هذا يتطلب تمرير النص الصحيح للسورة/الآية المختارة (من قاعدة بيانات مثاني الموجودة مسبقاً) — استخدم ما لديك بالفعل من نص القرآن في التطبيق.

---

<a name="المرحلة-سبعة"></a>
## ٩. المرحلة سبعة: الاختبار الشامل

### قائمة تحقق نهائية قبل اعتبار V1 جاهزاً

اختبر كل نقطة ودوِّن ✅ أو ❌:

```
[ ] التطبيق يطلب إذن الميكروفون بشكل صحيح
[ ] النموذج يُحمّل بنجاح عند فتح شاشة التسميع لأول مرة
[ ] التسجيل يبدأ ويتوقف بدون تعطل التطبيق
[ ] النص الناتج من Whisper منطقي لآيات قصيرة (الإخلاص، الفلق)
[ ] النص الناتج منطقي لآيات أطول (آية الكرسي)
[ ] المطابقة تُظهر كلمات صحيحة باللون الأخضر
[ ] المطابقة تُظهر كلمات خاطئة باللون الأحمر (جرّب قراءة كلمة خاطئة عمداً)
[ ] المطابقة تُظهر كلمات ناقصة كرمادي (توقف عن القراءة في المنتصف عمداً)
[ ] التطبيق يعمل بدون اتصال إنترنت (فعّل وضع الطيران واختبر)
[ ] لا يحدث تعطل (crash) عند تكرار العملية عدة مرات متتالية
```

### اختبار على أجهزة متعددة

جرّب على:
- جهاز Android متوسط المواصفات
- جهاز Android قوي (Snapdragon 8 Gen 2/3 إن أمكن)
- iPhone إن كان متاحاً

سجّل زمن المعالجة على كل جهاز لآية متوسطة الطول.

---

<a name="ملحق-المشاكل"></a>
## ملحق: حل المشاكل الشائعة

### المشكلة: النص الناتج فارغ تماماً

**الأسباب المحتملة:**
1. معدل العينة (Sample Rate) غير مطابق — تأكد أنه 16000Hz بالضبط في كل من التسجيل والنموذج
2. ملف الصوت تالف — جرّب تشغيله يدوياً في مشغل صوت للتأكد أنه سليم
3. مسار الملف خاطئ — أضف `print()` لطباعة المسار والتأكد من وجوده فعلاً

### المشكلة: `ImportError` عند التحويل في Colab

**الحل:**
أعد تشغيل الـ Runtime (`Runtime → Restart runtime`) ثم شغّل كل الخلايا من جديد بالترتيب.

### المشكلة: تطبيق Flutter يتعطل عند تحميل النموذج

**الأسباب المحتملة:**
1. نفدت الذاكرة (خاصة على أجهزة قديمة) — تحقق من حجم النموذج مقارنة بذاكرة الجهاز
2. مسار asset خاطئ في `pubspec.yaml` — تأكد من التطابق الحرفي للمسار

### المشكلة: `sherpa_onnx` لا يُثبَّت بنجاح

**الحل:**
تأكد أن لديك:
```bash
flutter --version  # يجب أن يكون 3.x أو أحدث
```
وجرّب:
```bash
flutter clean
flutter pub get
```

### المشكلة: النموذج بطيء جداً (أكثر من 15 ثانية لآية قصيرة)

**الأسباب المحتملة:**
1. تعمل على المحاكي (Emulator) وليس جهازاً حقيقياً — المحاكي أبطأ بكثير
2. الجهاز لا يدعم تسريع NPU — هذا طبيعي على CPU، لكن يجب ألا يتجاوز 15 ثانية

---

## الخطوات التالية بعد إتمام هذا الدليل

بعد نجاح كل ما سبق، تكون قد أنجزت **V1 كاملاً**. الخطوات التالية (خارج نطاق هذا الملف):

1. ربط الشاشات ببعضها بتدفق كامل (اختيار سورة → تسجيل → نتيجة)
2. حفظ جلسات التسميع في قاعدة البيانات (Isar)
3. تحسين واجهة المستخدم (تصميم، حركات انتقال)
4. البدء بـ V2 (تقييم التجويد) باستخدام cpfair JSON

---

**نهاية الدليل — بالتوفيق 🤲**