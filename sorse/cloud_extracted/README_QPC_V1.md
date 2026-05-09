# 🕌 نظام QPC V1 المحسّن - مصحف المدينة القديم

## ✨ المميزات

- ✅ **عرض احترافي** للمصحف بالخط الأصلي من مجمع الملك فهد
- ✅ **أداء عالي** مع Lazy Loading و Caching ذكي
- ✅ **دعم شامل** لـ Web و Native (Android/iOS)
- ✅ **معالجة محكمة للأخطاء** مع تشخيص ذاتي
- ✅ **بنية نظيفة** و موثّقة بالكامل
- ✅ **اختبارات شاملة** مع أدوات تشخيص

## 📁 هيكل المشروع

```
lib/data/
├── models/
│   └── qpc_v1_models.dart          # النماذج الأساسية
├── services/
│   ├── qpc_v1_database_service.dart # إدارة قاعدة البيانات
│   └── qpc_v1_font_service.dart     # إدارة الخطوط
└── widgets/
    ├── qpc_v1_page_widget.dart      # Widget العرض الرئيسي
    ├── qpc_v1_test_screen.dart      # شاشة الاختبار
    └── qpc_v1_diagnostics.dart      # أداة التشخيص
```

## 🚀 البدء السريع

### 1. التثبيت

انسخ الملفات المرفقة إلى مشروعك:

```bash
# الملفات المطلوبة
qpc_v1_models.dart
qpc_v1_database_service.dart
qpc_v1_font_service.dart
qpc_v1_page_widget.dart
qpc_v1_test_screen.dart
qpc_v1_diagnostics.dart
```

### 2. التبعيات

أضف إلى `pubspec.yaml`:

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
  http: ^1.1.0
  path_provider: ^2.1.1

assets:
  - assets/data/qpc_v1_layout.db
  - assets/data/qpc_v1_glyphs.json
```

### 3. الاستخدام الأساسي

```dart
import 'package:flutter/material.dart';
import 'qpc_v1_page_widget.dart';

class MyQuranApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('المصحف')),
        body: QPCV1PageWidget(
          pageNumber: 1,
          onPageLoaded: () => print('Page loaded!'),
        ),
      ),
    );
  }
}
```

### 4. الاختبار

```dart
import 'qpc_v1_test_screen.dart';

// في main.dart
runApp(MaterialApp(
  home: QPCV1TestScreen(),
));
```

## 🔧 التكوين المتقدم

### تخصيص الألوان

```dart
// في qpc_v1_page_widget.dart
const Color pageBackgroundColor = Color(0xFFF5F3E8);
const Color textColor = Color(0xFF000000);
const Color accentColor = Color(0xFF8B6914);
```

### تخصيص الخطوط

```dart
TextStyle(
  fontFamily: fontFamily,
  fontSize: 24,        // حجم الخط
  height: 1.8,         // المسافة بين الأسطر
  letterSpacing: 0,    // المسافة بين الحروف
)
```

### Preloading ذكي

```dart
// تحميل مسبق للصفحات المحيطة
await fontService.preloadSurroundingPages(
  currentPage, 
  range: 3  // عدد الصفحات قبل وبعد
);
```

## 📊 الأداء

### معايير الأداء

| المقياس | القيمة |
|---------|--------|
| تحميل صفحة | < 500ms |
| حجم الخط | ~50KB |
| استهلاك الذاكرة | ~10MB |
| Cache الصفحات | غير محدود |

### نصائح التحسين

```dart
// 1. تحميل مسبق
await fontService.preloadPages([1, 2, 3, 4, 5]);

// 2. مسح Cache عند الحاجة
dbService.clearCache();
fontService.clearMemoryCache();

// 3. مراقبة الأداء
final stats = fontService.getStatistics();
print('Loaded fonts: ${stats['loaded_pages']}');
```

## 🐛 استكشاف الأخطاء

### مشكلة: الخط لا يظهر

**الأعراض:** مربعات □□□ بدلاً من النص

**الحلول:**
```dart
// 1. تحقق من تحميل الخط
final loaded = await fontService.loadPageFont(pageNumber);
print('Font loaded: $loaded');

// 2. مسح Cache
await fontService.clearLocalCache();

// 3. تشغيل التشخيص
final report = await QPCV1Diagnostics().runFullDiagnostics();
QPCV1Diagnostics.showReport(context, report);
```

### مشكلة: قاعدة البيانات لا تُقرأ

**الأعراض:** Error loading page

**الحلول:**
```dart
// 1. تحقق من وجود الملف
// assets/data/qpc_v1_layout.db

// 2. فحص قاعدة البيانات
final dbInfo = await dbService.getDatabaseInfo();
print(dbInfo);

// 3. إعادة النسخ من Assets
await dbService.dispose();
await dbService.initialize();
```

### مشكلة: بطء التحميل

**الأعراض:** التطبيق يتجمد عند التحميل

**الحلول:**
```dart
// 1. استخدام Lazy Loading
// (مطبّق افتراضياً)

// 2. تقليل Preloading
await fontService.preloadSurroundingPages(page, range: 1);

// 3. مسح Cache الذاكرة
fontService.clearMemoryCache();
```

## 🔍 التشخيص الشامل

```dart
// تشغيل فحص شامل
final diagnostics = QPCV1Diagnostics();
final report = await diagnostics.runFullDiagnostics();

// عرض النتائج
QPCV1Diagnostics.showReport(context, report);

// طباعة التقرير
print('Health: ${report.isHealthy}');
print('Passed: ${report.passedCount}/${report.checks.length}');
```

## 📱 دعم المنصات

### ✅ Android
- مدعوم بالكامل
- Cache محلي
- تحميل تلقائي

### ✅ iOS
- مدعوم بالكامل
- Cache محلي
- تحميل تلقائي

### ⚠️ Web
- مدعوم مع قيود
- Cache في الذاكرة فقط
- يحتاج CORS Proxy

### ❌ Desktop
- غير مدعوم حالياً
- قيد التطوير

## 🎯 حالات الاستخدام

### 1. تطبيق قراءة بسيط

```dart
PageView.builder(
  itemCount: 604,
  itemBuilder: (context, index) {
    return QPCV1PageWidget(
      pageNumber: index + 1,
    );
  },
)
```

### 2. تطبيق مع بحث

```dart
// يمكن دمجه مع نظام البحث الموجود
final searchResults = await quranRepo.searchAyahs(query);

// الانتقال إلى الصفحة
final pageNumber = navigationProvider.getPageForAyah(
  searchResults.first.surahNumber,
  searchResults.first.ayahNumber,
);

pageController.jumpToPage(pageNumber - 1);
```

### 3. تطبيق مع إشارات مرجعية

```dart
class BookmarkedPage extends StatelessWidget {
  final int pageNumber;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        QPCV1PageWidget(pageNumber: pageNumber),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () => saveBookmark(pageNumber),
          ),
        ),
      ],
    );
  }
}
```

## 📈 الإحصائيات

```dart
// إحصائيات قاعدة البيانات
final dbInfo = await dbService.getDatabaseInfo();
print('Cached pages: ${dbInfo['cached_pages']}');
print('Cached glyphs: ${dbInfo['cached_glyphs']}');

// إحصائيات الخطوط
final fontStats = fontService.getStatistics();
print('Loaded fonts: ${fontStats['loaded_pages']}');
print('Memory cache: ${fontStats['cached_fonts_memory']}');

// حجم Cache
final cacheSize = await fontService.getLocalCacheSize();
print('Cache size: ${(cacheSize/1024/1024).toStringAsFixed(2)} MB');
```

## 🔒 الأمان

- ✅ لا يتم جمع أي بيانات مستخدم
- ✅ جميع البيانات محلية
- ✅ لا توجد اتصالات خارجية (بعد التحميل الأولي)
- ✅ يمكن مسح جميع البيانات بسهولة

## 🤝 المساهمة

نرحب بالمساهمات! يرجى:

1. Fork المشروع
2. إنشاء Branch للميزة
3. Commit التغييرات
4. Push للـ Branch
5. فتح Pull Request

## 📝 الترخيص

- **الخطوط:** QPC V1 من مجمع الملك فهد (مجانية)
- **البيانات:** القرآن الكريم (مصدر عام)
- **الكود:** MIT License

## 📞 الدعم

### الأسئلة الشائعة

**س: هل يعمل بدون إنترنت؟**  
ج: نعم، بعد التحميل الأولي للخطوط

**س: ما حجم التطبيق؟**  
ج: ~30MB (مع جميع الخطوط)

**س: هل يدعم التكبير/التصغير؟**  
ج: يمكن إضافة هذه الميزة بسهولة

**س: كيف أغيّر الخط؟**  
ج: النظام مصمم للخطوط الأصلية فقط

### روابط مفيدة

- [دليل التكامل الكامل](QPC_V1_INTEGRATION_GUIDE.md)
- [مستودع مجمع الملك فهد](https://qurancomplex.gov.sa)
- [Flutter Documentation](https://flutter.dev)

---

**صُنع بـ ❤️ للمسلمين في كل مكان**

اللهم اجعل هذا العمل خالصاً لوجهك الكريم 🤲
