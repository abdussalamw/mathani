# توثيق الـ API

يعتمد تطبيق مثاني على مصادر بيانات متعددة، أهمها:

## 1. AlQuran Cloud API
- **Base URL**: `https://api.alquran.cloud/v1`
- **Documentation**: [alquran.cloud/api](https://alquran.cloud/api)

### Endpoints المستخدمة:
- `GET /surah`: لجلب قائمة السور (metadata).
- `GET /quran/quran-uthmani`: لجلب النص القرآني كاملاً (للاستخدام Offline).
- `GET /edition`: لجلب قائمة القراء والتفاسير المتاحة.

## 2. GitHub Assets (للمشروع)
- **Repo**: `abdussalamw/mathani`
- **Release Assets**: تستخدم لتحميل ملفات الخطوط الكبيرة (QCF) والبيانات المضغوطة لتقليل حجم التطبيق الأولي.

### هيكل البيانات (Data Structure)

#### Surah Model
```json
{
  "number": 1,
  "name": "سورة الفاتحة",
  "englishName": "Al-Fatiha",
  "numberOfAyahs": 7,
  "revelationType": "Meccan"
}
```

## التخزين المحلي (Isar)
يتم تخزين البيانات محلياً باستخدام Isar للحصول على أداء فائق ودعم Offline.
- `SurahCollection`: تخزين قائمة السور.
- `AyahCollection`: تخزين الآيات (6236 آية).
- `MushafMetadata`: تخزين حالة المصاحف (محملة/غير محملة).
