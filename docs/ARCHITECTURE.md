# البنية المعمارية لمثاني

## نظرة عامة

يتبع مثاني معمارية Clean Architecture مع فصل واضح للطبقات:
`Presentation` → `Domain` → `Data`

## الطبقات

### 1. Presentation Layer
- **الدور**: واجهات المستخدم وإدارة الحالة
- **الموقع**: `lib/presentation/`
- **المكونات**:
  - `Screens`: الشاشات الكاملة (مثل `MushafScreen`, `SurahListScreen`).
  - `Widgets`: المكونات القابلة لإعادة الاستخدام.
  - `Providers`: إدارة الحالة باستخدام مكتبة Provider.

### 2. Domain Layer
- **الدور**: منطق الأعمال الأساسي (مستقبلاً)
- **الموقع**: `lib/domain/` (مجهز)
- **المكونات**:
  - `Entities`: الكيانات الأساسية المجردة.
  - `Use Cases`: حالات الاستخدام (مثل "تشغيل آية", "جلب تفسير").
  - `Repositories Interfaces`: العقود (Contracts) التي يجب أن تنفذها طبقة البيانات.

### 3. Data Layer
- **الدور**: التعامل مع البيانات والمصادر الخارجية
- **الموقع**: `lib/data/`
- **المكونات**:
  - `Models`: تمييز البيانات (مثل `Surah`, `Ayah` في `collections.dart`).
  - `Repositories`: تنفيذ المنطق الفعلي لجلب البيانات (مثل `QuranRepository`).
  - `Data Sources`: الاتصال المباشر (مثل `RemoteDataSource` للـ API, `IsarService` للداتابيز).

## تدفق البيانات (Data Flow)

User Action (UI) 
     ↓
Provider (ChangeNotifier)
     ↓
Repository
     ↓
Data Source (Local DB / Remote API)

## التقنيات الرئيسية

- **Isar Database**: لقاعدة البيانات المحلية السريعة وتخزين المصحف.
- **Provider**: لإدارة الحالة (State Management).
- **Dio**: للاتصال بالشبكة وتحميل الملفات.
