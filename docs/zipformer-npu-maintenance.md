# تشغيل Zipformer V3 على NPU في مثاني

هذا مرجع لإعادة إعداد المسار الذي جُرّب على **Galaxy S24 Ultra ‏(SM-S928B)** بشريحة **Snapdragon SM8650**، ولتشخيصه عند تغيير النموذج أو مكتبات Android. نجح التسميع الحي في تجربة المستخدم على النسخة **1.0.2 (18)** بتاريخ 20 نوفمبر 2026، بعد تجهيز ملفاتها على الهاتف عبر USB. كان استدلال النموذج على **Hexagon HTP v75**، مع تعطيل الرجوع إلى CPU. يبقى تجهيز الصوت وفك CTC ومطابقة التلاوة ومعالجة الواجهة خارج استدلال النموذج.

## ما حلّ المشكلة

1. **تثبيت أبعاد النموذج المتدفق.** بدأنا من تصدير Quran Lab الأصلي `zipformer_p_arabic_v3.int8.onnx`. ثبّتنا بُعد الدفعة `N=1` واستنتجنا أبعاد الرسم، مع فحص بقاء العمليات والأوزان على حالها بعد استنتاج الأبعاد. تحقق السكربت من 99 مدخلًا و99 مخرجًا، من بينها 98 زوجًا لحالة البث. شكل الميزات `[1, 61, 80]` وشكل خرج CTC ‏`[1, 12, 251]`. [سكربت التهيئة](../scripts/prepare_zipformer_npu_candidate.py)
2. **استقرار الدقة على HTP.** جهّز QNN نسخة بالأبعاد الثابتة وعمل الاستدلال على المسرّع، لكن مقارنة الرموز أظهرت 8 و13 و2 تعديلات في ثلاث عينات. عالجنا 84 موضعًا من دالة Softplus بصيغة مكافئة تقلل خطر تجاوز مدى FP16. تستبدل `log(1 + exp(x))` بـ `max(x, 0) + log(1 + exp(-abs(x)))`، بحيث لا يُمرَّر إلى `exp` طرف موجب كبير. بعد ذلك تطابقت رموز العينات السبع مع خرج النموذج الأصلي. لم نحتج إلى إعادة تدريب الأوزان أو إعادة تصديرها من PyTorch. [تنفيذ التحويل](../scripts/prepare_zipformer_npu_candidate.py)
3. **تجميع الرسم مسبقًا.** أنشأنا سياق QNN مخصصًا لـ `SM8650` و`HTP v75`. نتج ملف ONNX صغير بعقدة `EPContext` وملف `.bin` خارجي يحتوي السياق المجمّع. يجب أن يبقيا بالاسمين المتوقعين في مجلد واحد. توقف مسار LiteRT التجريبي أثناء تحويل الرسم، لذلك كان التحقق الفعلي لمسار QNN. [توثيق سياق QNN](https://onnxruntime.ai/docs/execution-providers/QNN-ExecutionProvider.html#qnn-context-binary-cache-feature)
4. **عزل مكتبات التشغيل.** يستخرج Gradle ملفات ARM64 المحددة من AARs بعد التحقق من SHA‑256. يفتح جسر C++ نسخة ONNX Runtime الخاصة بـ Zipformer باسم `libmathani_ort.so`، ويسجّل QNN من المكتبة المرافقة. يحتفظ Sherpa بنسخته الخاصة من ORT. يعتمد FastRPC على إتاحة ملف Hexagon الفعلي في مجلد المكتبات الأصلية، لذا يستعمل البناء `useLegacyPackaging` ويحفظ `libQnnHtpV75Skel.so` دون تجريده. يضيف Kotlin هذا المجلد إلى `ADSP_LIBRARY_PATH`. [إعداد Gradle](../android/app/build.gradle.kts) · [جسر C++](../android/app/src/main/cpp/zipformer_qnn.cpp) · [قناة Android](../android/app/src/main/kotlin/com/example/mathani/ZipformerNpuChannel.kt)

## بيئة Android المعتمدة

| الجزء | النسخة أو القيد |
| --- | --- |
| الهاتف والشريحة | Samsung ‏`SM-S928B` على `SM8650` |
| شرط تشغيل المسار | عملية `arm64-v8a`، Android 12 أو أحدث حسب شرط القناة، والشريحة `SM8650`. إثبات التشغيل الفعلي يخص الهاتف الذي جُرّب |
| ONNX Runtime | `com.microsoft.onnxruntime:onnxruntime-android:1.29.0` |
| موفّر QNN | `com.qualcomm.qti:onnxruntime-android-qnn:2.7.0` |
| مكتبات QNN / QAIRT | `com.qualcomm.qti:qnn-runtime:2.51.0`، مع `libQnnHtp.so` و`libQnnSystem.so` وملفي `V75Stub` و`V75Skel` |
| بناء الجسر | CMake ‏3.22.1 وC++17. تؤخذ نسخة Flutter من [ملف FVM](../.fvmrc) وتثبيت الأدوات من [إعداد Android](../android/app/build.gradle.kts) |

تبدأ قناة `mathani/zipformer_npu` بفحص التوافق ووجود المكتبات. عند فتح الجلسة، يطلب C++ جهازًا يعلن نوعه `NPU`، ويضبط `session.disable_cpu_ep_fallback=1` و`offload_graph_io_quantization=0`. تشغّل القناة دفعتين صامتتين، ويتحقق C++ من زيادة عداد الإطارات بـ24 في كل دفعة. بعد ذلك تصفّر حالة البث قبل فتح الميكروفون. هذا الاختبار مختلف عن فحص وجود المكتبات وحده. [فتح الجلسة](../lib/core/services/recitation/zipformer_android_npu.dart) · [تنفيذ الاختبار وإعادة الحالة](../android/app/src/main/kotlin/com/example/mathani/ZipformerNpuChannel.kt)

أثناء الجلسة يحوّل Kotlin الصوت أحادي القناة عند 16 كيلوهرتز إلى 80 قناة Mel بخوارزمية Fbank متوافقة مع مرجع Kaldi. تتكوّن نافذة النموذج من 61 إطارًا، والخطوة 48 إطارًا، أي 480 مللي ثانية من الصوت. يعيد جسر C++ تدوير حالة النموذج الأصلية بين الدفعات. يفك Kotlin رموز CTC بإزالة الرموز المكررة و`<blank>` ذي المعرّف 250، ثم تُطابَق الفونيمات في Dart مع مرجع الآيات. [ميزات الصوت](../android/app/src/main/kotlin/com/example/mathani/ZipformerFbank.kt) · [مطابقة الآيات](../lib/core/services/recitation/zipformer_alignment.dart)

## إعادة تجهيز سياق QNN

1. احصل على إصدار V3 من [مصدر النموذج](https://huggingface.co/Quran-Lab/zipformer_p-arabic-v3) وفق شروط الوصول. ملف الإدخال الذي استُخدم حجمه 72,705,392 بايت وبصمته `6a5ddafa9c5e5c01260d30264031b341785bdc152e9ef1d569b41c8c278508eb`. احفظه محليًا باسم `model_zipformer/zipformer_p_arabic_v3.int8.onnx`.
2. تحقّق من الأبعاد والعمليات وأخرج مرشحًا جديدًا. كان Python ‏3.12 مستخدمًا في بيئة التجارب، وكانت حزم استنتاج الأبعاد `onnx==1.20.1` و`onnxruntime==1.26.0`. يحمي السكربت الملف القائم ويرفض استبداله. يحسب أيضًا بصمات المصدر والناتج.

   ```powershell
   Get-FileHash -Algorithm SHA256 model_zipformer/zipformer_p_arabic_v3.int8.onnx
   python -B scripts/prepare_zipformer_npu_candidate.py model_zipformer/zipformer_p_arabic_v3.int8.onnx .dart_tool/zipformer_npu/repro/zipformer-v3-stable-softplus.onnx --fp16-safe
   ```

   بصمة المرشح المستقر في التجربة `f2fd4d949d430cdd80bd8a823f8342517475b28513a0802b7f5dad6293ea78b4`. تُراجع أي بصمة مختلفة قبل اعتماد المرشح.
3. استخدم بيئة تجميع منفصلة فيها `onnxruntime==1.29.0` و`onnxruntime-qnn==2.7.0`. المقتطف التالي يعيد إعداد جلسة التهيئة التي جُمّع بها السياق على Windows. تكفي تهيئة الجلسة لإنتاج الملفين.

   ```python
   from pathlib import Path

   import onnxruntime as ort
   import onnxruntime_qnn as qnn

   work = Path(".dart_tool/zipformer_npu/repro").resolve()
   source = work / "zipformer-v3-stable-softplus.onnx"
   context = work / "zipformer-v3-sm8650-softplus_ctx.onnx"
   binary = work / "zipformer-v3-sm8650-softplus_ctx_qnn.bin"
   if not source.is_file() or context.exists() or binary.exists():
       raise RuntimeError("Expected an existing candidate and new output paths")

   provider = "QNNExecutionProvider"
   ort.disable_telemetry_events()
   ort.register_execution_provider_library(provider, qnn.get_library_path())
   try:
       devices = [device for device in ort.get_ep_devices() if device.ep_name == provider]
       if not devices:
           raise RuntimeError("QNN compilation device unavailable")

       options = ort.SessionOptions()
       options.add_session_config_entry("session.disable_cpu_ep_fallback", "1")
       options.add_session_config_entry("ep.context_enable", "1")
       options.add_session_config_entry("ep.context_file_path", str(context))
       options.add_provider_for_devices(devices[:1], {
           "backend_path": qnn.get_qnn_htp_path(),
           "soc_model": "SM8650",
           "htp_arch": "75",
           "enable_htp_prepare_only": "1",
           "offload_graph_io_quantization": "0",
       })
       session = ort.InferenceSession(str(source), sess_options=options)
       del session
       if not context.is_file() or not binary.is_file():
           raise RuntimeError("Expected both QNN context files")
   finally:
       ort.unregister_execution_provider_library(provider)
   ```

4. افحص حجم الملفين وبصمتيهما مقابل الجدول التالي. أي ترقية للنموذج أو ORT أو QNN تتطلب إعادة اختبار التوافق، والتأكد من تنفيذ العقد على QNN، ومقارنة الرموز على عينات معلومة قبل اعتماد حزمة جديدة. راجع الأسماء والأحجام في Android والبصمات في Dart معًا.

| ملف الحزمة المعتمدة | بايت | SHA‑256 |
| --- | ---: | --- |
| `zipformer-v3-sm8650-softplus_ctx.onnx` | 13,204 | `4b4f09aadf80a2ff23609111c0e19d8a711ff3a137e1e4c7d2e3b694a266dc41` |
| `zipformer-v3-sm8650-softplus_ctx_qnn.bin` | 151,097,344 | `e596c3753a5f389f495d50b94bfd5bb3ae4037d6b6c0df9332f7184daeccccc3` |
| `ordered_quran_phonemes.json` | 12,827,409 | `af54b04918cb46873dc9f7c9bac48be3b9f0a41d57be8f1659cdd2d8f09e5c50` |
| `tokens.txt`، مضمّن في التطبيق | 2,597 | `ed1cf15923b96a8c6fb4b2e03791d1ec2e5d09aa2dac99086e1b3175986a581f` |

يحتاج التنزيل الكامل إلى 163,937,957 بايت تقريبًا، ويقل العدد الفعلي عند وجود مرجع مطابق على الهاتف. يستقبل التطبيق كل ملف في مسار مؤقت ويفحص الحجم والبصمة قبل نقله إلى مكانه. تقرأ القناة جدول الرموز المضمّن الموافق لنموذج V3 ذي 251 رمزًا. [بصمات الحزمة](../lib/core/services/recitation/zipformer_npu_package.dart) · [التنزيل والتحقق](../lib/core/services/recitation/recitation_model_downloader.dart) · [جدول الرموز](../assets/data/tokens.txt)

## ما ثبت على الهاتف

- أُجريت مقارنة على سبع عينات تلاوة للعفاسي والحصري تشمل الفاتحة 2 و7 والإخلاص 1 وآية الكرسي. تطابقت معرفات CTC بعد فكها مع النموذج الأصلي في العينات السبع، بعد 215 دفعة إجمالًا. فصل اختبار Kotlin/JNI بين سلامة حساب الميزات وتطابق خرج النموذج، ثم أعاد الاختبار باستخدام المكتبات الفعلية الخارجة من Gradle.
- أظهر ملف تتبّع ONNX Runtime على الهاتف **215 استدعاء لـQNN وصفر عقد نموذج على CPU**. متوسط الدفعة **42.4 مللي ثانية** وأقصاها **56 مللي ثانية** مقابل خطوة صوتية 480 مللي ثانية. هذه قياسات دفعات الاستدلال المجرّبة. قياس زمن التقاط أول كلمة ووصول التنبيه والحرارة في جلسة طويلة يحتاج تجربة مباشرة.
- استخدمت النسخة **1.0.2 (18)** تنزيلًا محليًا عبر `adb reverse`. بعد التثبيت نُزّل ملفا السياق وتحقق التطبيق من سلامتهما، ثم أكد المستخدم نجاح التسميع الحي. جُمّعت النسخة التجريبية بوضع `release` وتوقيع `debug` الحالي. حجم APK لتلك التجربة 87,394,809 بايت مستقل عن ملفات النموذج. بصمته `ec6c455e5d68f44700fd1738fccea6cb6c07cb5553e6ece349fc646dbf681a95`. [إعداد التوقيع](../android/app/build.gradle.kts)
- كانت أدلة الاختبار المحلية في `.dart_tool/zipformer_npu` ومنها `s24-ultra-npu-proof.json` و`s24-ultra-validation-summary.json` و`s24-ultra-gradle-release-jni.log`. الأرقام أعلاه حصيلة هذه العينات وتهيئة الهاتف المذكورة.

## إعادة تجربة USB

تنطبق [قواعد البناء والأجهزة](../AGENTS.md) قبل بناء APK أو تثبيته. بعد تفويض العمل على الهاتف، جهّز مجلدًا محليًا يضم ملفات الحزمة الثلاثة المنزّلة فقط. النسخة التجريبية تستعمل تعريف البناء `MATHANI_ZIPFORMER_NPU_TEST_BASE_URL=http://127.0.0.1:8769/`؛ الشرطة المائلة الأخيرة مطلوبة. ملف APK العادي يستعمل عنوان التنزيل المعتمد في المصدر.

```powershell
python -B -m http.server 8769 --bind 127.0.0.1 --directory .dart_tool/zipformer_npu/local_delivery
```

نفّذ أوامر ADB في نافذة أخرى بعد التحقق من الجهاز المقصود. عند وجود أكثر من جهاز، اختره صراحة باستعمال `adb -s`.

```powershell
adb devices -l
adb reverse tcp:8769 tcp:8769
adb reverse --list
```

من التطبيق افتح مركز التنزيل ونزّل ملفات Zipformer، ثم ابدأ جلسة وافتح تقرير التشخيص للتحقق من نتيجة الاستدلال. بعد انتهاء الاختبار أزل إعادة توجيه هذا المنفذ بـ `adb reverse --remove tcp:8769` وأوقف الخادم المحلي. تبقى الملفات المطابقة في مساحة التطبيق، ويمكن إجراء التسميع دون اتصال بعد تجهيزها.

## تشخيص الأعطال

| العرض | موضع الفحص |
| --- | --- |
| الشريحة غير مدعومة أو المزوّد غير متاح | افحص قيمة `Build.SOC_MODEL`، وABI العملية، وإصدار Android، ونوع الجهاز المعلن من QNN. توسيع الدعم إلى شريحة أخرى يحتاج سياقًا ومكتبات واختبارًا عليها. |
| يوجد توافق للجهاز لكن اختبار الاستدلال يفشل | افحص تطابق ملفات السياق أولًا، ثم إصدارات AAR وSHA‑256، وإتاحة `libQnnHtpV75Skel.so` بعد التثبيت، و`ADSP_LIBRARY_PATH`، ومخرجات `adb logcat -d -s MathaniZipformer`. استبقاء `session.disable_cpu_ep_fallback=1` يجعل فشل التنفيذ ظاهرًا. |
| ملف ناقص أو خطأ HTTP ‏404 | افحص وجود الاسم حرفيًا عند مصدر التنزيل، أو تهيئة `adb reverse` في نسخة USB. قارن الحجم وSHA‑256 قبل إعادة تجهيز الملف. |
| النموذج يعمل لكن الحروف تتغيّر أو بداية التلاوة تتعطل | افصل اختبار الرموز عن التسجيل الحي. قارن خرج CTC بصوت مرجعي، ثم افحص نموذج Fbank وأبعاد النوافذ، وترتيب `tokens.txt`، وتهيئة التسجيل، ومرجع الفونيمات. |
| النص معروف لكن التسميع يتوقف عند كلمة أو لا يقلب الصفحة | راجع مطابقة الآية والانتقال منها في Dart، ثم تحقق من موضع العرض في القارئ. قد يعمل NPU بينما تظل المطابقة بانتظار أدلة كافية. |

يجمع تقرير التطبيق فحص الملفات وتوافق الجهاز وإذن الميكروفون ونتيجة آخر تهيئة ناجحة للمسرّع. اختبر ربط الميكروفون بالسلوك الحي بعد الإذن، واحفظ في التقارير التقنية القياسات دون تسجيلات القراء أو بياناتهم. [خدمة التشخيص](../lib/data/services/recitation_diagnostic_service.dart)

## التوزيع والصيانة

- عنوان إنتاج الحزمة هو إصدار الأصول `v1.0-assets` على GitHub. وقت التحقق كان الإصدار يحتوي ONNX القديم ومرجع الفونيمات وجدولًا قديمًا، وملفا **سياق QNN** لم يكونا متاحين فيه. تعمل النسخة المجهّزة محليًا على الهاتف، أما تنزيل جديد من المصدر الافتراضي فيتوقف على إتاحة الملفين هناك أو اعتماد مصدر توزيع مكافئ. توثيق المصدر وتجربة USB المكتملة دليلان على حالة منفصلة عن جاهزية التوزيع. [مصدر التنزيل في التطبيق](../lib/core/services/recitation/recitation_model_downloader.dart)
- احفظ الأوزان وملفات التجميع وAAR وملفات التوقيع ومخرجات APK والتسجيلات خارج تغييرات Git. قبل أي توزيع لاحق راجع شروط إعادة توزيع ملفات النموذج المحوّلة ومرجع الفونيمات وجدول الرموز. يتطلب ترخيص Quran Lab الاحتفاظ بنص الترخيص عند توزيع العمل أو مشتقاته وتوزيع المشتقات بنفس الشروط، وألا يُفرض مقابل للوصول إلى النموذج أو الميزة التي يشغّلها. راجع أيضًا شروط توزيع مكتبات التنفيذ عند نشر تطبيق يحتويها. [ترخيص النموذج NPL‑1.2](https://huggingface.co/Quran-Lab/zipformer_p-arabic-v3/blob/main/LICENSE)
- يظل ضغط حزمة التنزيل تغييرًا لاحقًا. أعطى ضغط الملفات الثلاثة محليًا نحو **74.0 ميغابايت بـZIP** و**66.6 ميغابايت بـXZ** مع حفظ الملفات الأصلية. يحتاج اختيار الضغط إلى قياس زمن الفك والمساحة المؤقتة على الهاتف. استخدام الملف الأصغر في الشبكة لا يغيّر بصمة كل ملف بعد الفك.
- يُختبر تطوير التسميع على مراحل تبدأ بالتقاط الكلمة الأولى وانتظار الاستعاذة أو البسملة، ثم استئناف المحاذاة بعد التجاوز، وثبات تقليب الصفحة، وعرض آخر الكلمات باتجاه RTL. تقاس الاستجابة والإنذارات الخاطئة في جلسة طويلة. يشمل اختبار أي حزمة جديدة مقارنة الرموز وإثبات تنفيذ NPU من جديد. [اختبارات جلسة التسميع](../test/unit/services/zipformer_session_test.dart) · [اختبارات بث الصوت](../test/unit/services/zipformer_live_recitation_test.dart)
