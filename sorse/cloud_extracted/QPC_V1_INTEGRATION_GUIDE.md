# دليل تكامل نظام QPC V1 المحسّن

## 📋 نظرة عامة

تم بناء نظام محسّن وشامل لعرض مصحف المدينة القديم (QPC V1) بالخطوط الأصلية من مجمع الملك فهد.

## 🏗️ البنية المعمارية

### 1. النماذج (Models)
- **qpc_v1_models.dart**: نماذج البيانات الأساسية
  - `QPCV1Page`: صفحة كاملة
  - `QPCV1Line`: سطر واحد
  - `QPCV1Word`: كلمة واحدة
  - `QPCV1LineType`: أنواع الأسطر

### 2. الخدمات (Services)
- **qpc_v1_database_service.dart**: إدارة قاعدة البيانات
  - تحميل وتخزين مؤقت للصفحات
  - استخراج البيانات من SQLite
  - ربط مع ملف JSON للـ Glyphs

- **qpc_v1_font_service.dart**: إدارة الخطوط
  - تحميل ذكي للخطوط
  - دعم Web و Native
  - Preloading للصفحات المحيطة

### 3. العرض (UI)
- **qpc_v1_page_widget.dart**: Widget للعرض
  - عرض احترافي للصفحة
  - معالجة الأخطاء
  - تحميل تلقائي

## 📦 التثبيت

### 1. نسخ الملفات

انسخ الملفات التالية إلى مشروعك:

```
lib/
├── data/
│   ├── models/
│   │   └── qpc_v1_models.dart
│   └── services/
│       ├── qpc_v1_database_service.dart
│       └── qpc_v1_font_service.dart
└── presentation/
    └── widgets/
        └── qpc_v1_page_widget.dart
```

### 2. التبعيات المطلوبة

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

### 3. إعداد الملفات

تأكد من وجود:
- `assets/data/qpc_v1_layout.db` - قاعدة البيانات
- `assets/data/qpc_v1_glyphs.json` - خريطة الرموز

## 🚀 الاستخدام

### مثال بسيط

```dart
import 'package:flutter/material.dart';
import 'qpc_v1_page_widget.dart';

class QuranPage extends StatelessWidget {
  final int pageNumber;
  
  const QuranPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة $pageNumber'),
      ),
      body: QPCV1PageWidget(
        pageNumber: pageNumber,
        onPageLoaded: () {
          print('Page loaded successfully');
        },
        onPageError: () {
          print('Error loading page');
        },
      ),
    );
  }
}
```

### مثال متقدم مع PageView

```dart
class QuranReader extends StatefulWidget {
  @override
  State<QuranReader> createState() => _QuranReaderState();
}

class _QuranReaderState extends State<QuranReader> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المصحف - صفحة $_currentPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showDatabaseInfo,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index + 1;
          });
        },
        itemCount: 604,
        itemBuilder: (context, index) {
          return QPCV1PageWidget(
            pageNumber: index + 1,
            onPageLoaded: () {
              debugPrint('Page ${index + 1} loaded');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToPage(context),
        child: Icon(Icons.search),
      ),
    );
  }

  void _goToPage(BuildContext context) async {
    final page = await showDialog<int>(
      context: context,
      builder: (context) => _PageSelectorDialog(),
    );
    
    if (page != null) {
      _pageController.jumpToPage(page - 1);
    }
  }

  void _showDatabaseInfo() async {
    final dbService = QPCV1DatabaseService();
    final info = await dbService.getDatabaseInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('معلومات قاعدة البيانات'),
        content: SingleChildScrollView(
          child: Text(info.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 التكوين المتقدم

### تخصيص الألوان

```dart
// في qpc_v1_page_widget.dart، عدّل الألوان:

const Color pageBackgroundColor = Color(0xFFF5F3E8); // لون الورق
const Color textColor = Color(0xFF000000); // لون النص
const Color accentColor = Color(0xFF8B6914); // لون التمييز
```

### تخصيص أحجام الخطوط

```dart
// في _buildLine method:

case QPCV1LineType.ayahText:
  textStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24, // غيّر هذا
    color: const Color(0xFF000000),
    height: 1.8,
  );
```

### تفعيل الـ Cache الذكي

```dart
// في main.dart أو عند بدء التطبيق:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة الخدمات
  final dbService = QPCV1DatabaseService();
  await dbService.initialize();
  
  runApp(MyApp());
}
```

## 🐛 استكشاف الأخطاء

### المشكلة: الخط لا يظهر

**الحل:**
```dart
// تحقق من تحميل الخط
final fontService = QPCV1FontService();
final loaded = await fontService.loadPageFont(pageNumber);
print('Font loaded: $loaded');

// تحقق من الإحصائيات
print(fontService.getStatistics());
```

### المشكلة: قاعدة البيانات لا تُقرأ

**الحل:**
```dart
// فحص قاعدة البيانات
final dbService = QPCV1DatabaseService();
await dbService.initialize();
final info = await dbService.getDatabaseInfo();
print('DB Info: $info');
```

### المشكلة: النص يظهر كمربعات □□□

**الأسباب المحتملة:**
1. الخط لم يُحمّل بعد
2. ملف الخط تالف
3. الترميز غير صحيح

**الحل:**
```dart
// مسح Cache وإعادة المحاولة
await fontService.clearLocalCache();
await fontService.loadPageFont(pageNumber);
```

## 📊 الأداء

### تحسينات مطبقة:

1. **Lazy Loading**: تحميل الخطوط عند الحاجة فقط
2. **Caching**: تخزين مؤقت للصفحات والخطوط
3. **Preloading**: تحميل مسبق للصفحات المحيطة
4. **Isolates**: معالجة JSON في خيوط منفصلة

### نصائح للأداء:

```dart
// تحميل مسبق للصفحات المحيطة
await fontService.preloadSurroundingPages(currentPage, range: 3);

// مسح Cache عند الحاجة
dbService.clearCache();
fontService.clearMemoryCache();
```

## 📈 المراقبة والتشخيص

### عرض الإحصائيات

```dart
// إحصائيات الخطوط
final fontStats = fontService.getStatistics();
print('Loaded pages: ${fontStats['loaded_pages']}');
print('Cache size: ${fontStats['cached_fonts_memory']}');

// إحصائيات قاعدة البيانات
final dbInfo = await dbService.getDatabaseInfo();
print('Cached pages: ${dbInfo['cached_pages']}');
print('Cached glyphs: ${dbInfo['cached_glyphs']}');
```

### حساب حجم Cache

```dart
final cacheSize = await fontService.getLocalCacheSize();
print('Cache size: ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB');
```

## 🔒 الأمان والخصوصية

- جميع البيانات محلية (لا يوجد اتصال بالإنترنت بعد التحميل الأولي)
- لا يتم جمع أي بيانات مستخدم
- Cache يمكن مسحه بالكامل في أي وقت

## 🆕 الميزات المستقبلية

- [ ] دعم البحث في النص
- [ ] دعم التفسير المدمج
- [ ] دعم التلاوة الصوتية
- [ ] دعم العلامات والملاحظات
- [ ] دعم الوضع الليلي

## 📞 الدعم

إذا واجهت أي مشكلة:

1. راجع سجل الأخطاء (Console Logs)
2. تحقق من وجود الملفات المطلوبة
3. جرب مسح Cache وإعادة المحاولة
4. تأكد من التبعيات صحيحة

## 📄 الترخيص

هذا النظام مبني على:
- خطوط QPC V1 من مجمع الملك فهد (مجانية للاستخدام)
- بيانات القرآن الكريم (مصدر عام)

---

**تم البناء بـ ❤️ للمسلمين في كل مكان**
