# 📖 مثاني - تطبيق القرآن الكريم

<div align="center">
  <img src="assets/images/logo/app_logo.png" width="150" />
  
  [![Flutter Version](https://img.shields.io/badge/Flutter-3.50.0-blue.svg)](https://flutter.dev/)
  [![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)
</div>

## 📱 نظرة عامة

**مثاني** هو تطبيق مفتوح المصدر لقراءة وتدبر القرآن الكريم، يجمع بين:
- ✨ تصميم عصري وأنيق
- 📖 عرض دقيق بالرسم العثماني
- 🎧 تلاوة صوتية عالية الجودة
- 📚 تفاسير متعددة
- 🎯 نظام حفظ ذكي
- 🌙 دعم الوضع الليلي

## 🎯 الميزات

### الميزات الحالية ✅
- [x] عرض المصحف بالرسم العثماني
- [x] قائمة السور والأجزاء
- [x] الوضع الفاتح والداكن

### قيد التطوير 🔄
- [ ] المشغل الصوتي
- [ ] التفاسير
- [ ] نظام الحفظ
- [ ] العلامات المرجعية

### مخطط مستقبلاً 📅
- [ ] تلوين التجويد
- [ ] الترجمات
- [ ] مواقيت الصلاة

## 🚀 البدء السريع

### المتطلبات
- Flutter 3.50.0 (الإصدار المثبت في `.fvmrc` والمستخدم في CI)
- Dart 3.14.0 المرفق مع Flutter
- Android Studio / VS Code

### التثبيت
```bash
# 1. استنساخ المستودع
git clone https://github.com/abdussalamw/mathani.git
cd mathani

# 2. تثبيت المكتبات
flutter pub get
dart run scripts/generate_localizations.dart

# 3. توليد ملفات قاعدة البيانات
dart run build_runner build

# 4. تشغيل التطبيق
flutter run
```

## 🏗️ البنية المعمارية

المشروع يستخدم **Clean Architecture** مع **Provider** لإدارة الحالة:
```
lib/
├── core/          # الثوابت والأدوات المشتركة
├── data/          # نماذج البيانات والمستودعات
├── domain/        # منطق الأعمال والكيانات
└── presentation/  # واجهات المستخدم
```

## 📚 التقنيات المستخدمة

- **Framework**: Flutter 3.19+
- **قاعدة البيانات**: Isar
- **إدارة الحالة**: Provider
- **الشبكة**: Dio
- **الصوتيات**: just_audio
- **الخطوط**: QCF2, Amiri, Tajawal, HafsSmart

## 🎨 الهوية البصرية

- **اللون الأساسي**: #E30613 (أحمر نسكافيه)
- **اللون الثانوي**: #D4AF37 (ذهبي)
- **النصوص**: #2C1810 (بني داكن)

## 🤝 المساهمة

نرحب بمساهماتكم! راجع [CONTRIBUTING.md](docs/CONTRIBUTING.md) للتفاصيل.

### خطوات المساهمة:
1. Fork المشروع
2. إنشاء branch للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push للـ branch (`git push origin feature/AmazingFeature`)
5. فتح Pull Request

## 📄 الترخيص

هذا المشروع مرخص تحت [GPL-3.0 License](LICENSE)

## 🙏 شكر وتقدير

- [AlQuran Cloud](https://alquran.cloud/) للـ API
- [EveryAyah.com](https://everyayah.com/) للتلاوات
- [مجمع الملك فهد](https://qurancomplex.gov.sa/) للمصحف

## 📞 التواصل

- المطور: [@abdussalamw](https://github.com/abdussalamw)
- المشروع: [github.com/abdussalamw/mathani](https://github.com/abdussalamw/mathani)

---

**"إِنَّا نَحْنُ نَزَّلْنَا الذِّكْرَ وَإِنَّا لَهُ لَحَافِظُونَ"**
