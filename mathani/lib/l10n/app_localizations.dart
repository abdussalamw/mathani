import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'مثاني'**
  String get appName;

  /// No description provided for @appNameEnglish.
  ///
  /// In ar, this message translates to:
  /// **'Mathani'**
  String get appNameEnglish;

  /// No description provided for @quran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get quran;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @surahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get surahs;

  /// No description provided for @juz.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get juz;

  /// No description provided for @hizb.
  ///
  /// In ar, this message translates to:
  /// **'الأحزاب'**
  String get hizb;

  /// No description provided for @mushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get mushaf;

  /// No description provided for @audio.
  ///
  /// In ar, this message translates to:
  /// **'الاستماع'**
  String get audio;

  /// No description provided for @listening.
  ///
  /// In ar, this message translates to:
  /// **'سماع'**
  String get listening;

  /// No description provided for @reading.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة'**
  String get reading;

  /// No description provided for @tafsir.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get tafsir;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @favorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favorites;

  /// No description provided for @bookmarks.
  ///
  /// In ar, this message translates to:
  /// **'العلامات'**
  String get bookmarks;

  /// No description provided for @recent.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة'**
  String get recent;

  /// No description provided for @lastRead.
  ///
  /// In ar, this message translates to:
  /// **'آخر موضع'**
  String get lastRead;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get continueReading;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة...'**
  String get searchHint;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get sort;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// No description provided for @surah.
  ///
  /// In ar, this message translates to:
  /// **'سورة'**
  String get surah;

  /// No description provided for @verses.
  ///
  /// In ar, this message translates to:
  /// **'آيات'**
  String get verses;

  /// No description provided for @verse.
  ///
  /// In ar, this message translates to:
  /// **'آية'**
  String get verse;

  /// No description provided for @ayah.
  ///
  /// In ar, this message translates to:
  /// **'آية'**
  String get ayah;

  /// No description provided for @ayahs.
  ///
  /// In ar, this message translates to:
  /// **'آيات'**
  String get ayahs;

  /// No description provided for @page.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get page;

  /// No description provided for @pages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get pages;

  /// No description provided for @part.
  ///
  /// In ar, this message translates to:
  /// **'جزء'**
  String get part;

  /// No description provided for @quarter.
  ///
  /// In ar, this message translates to:
  /// **'ربع'**
  String get quarter;

  /// No description provided for @meccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get medinan;

  /// No description provided for @revelation.
  ///
  /// In ar, this message translates to:
  /// **'النزول'**
  String get revelation;

  /// No description provided for @revelationOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب النزول'**
  String get revelationOrder;

  /// No description provided for @mushafOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب المصحف'**
  String get mushafOrder;

  /// No description provided for @surahNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم السورة'**
  String get surahNumber;

  /// No description provided for @ayahNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الآية'**
  String get ayahNumber;

  /// No description provided for @versesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الآيات'**
  String get versesCount;

  /// No description provided for @juzNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجزء'**
  String get juzNumber;

  /// No description provided for @pageNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة'**
  String get pageNumber;

  /// No description provided for @hizbNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحزب'**
  String get hizbNumber;

  /// No description provided for @sortBy.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get sortBy;

  /// No description provided for @filterBy.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب'**
  String get filterBy;

  /// No description provided for @alphabetical.
  ///
  /// In ar, this message translates to:
  /// **'أبجدياً'**
  String get alphabetical;

  /// No description provided for @byLength.
  ///
  /// In ar, this message translates to:
  /// **'حسب الطول'**
  String get byLength;

  /// No description provided for @shortest.
  ///
  /// In ar, this message translates to:
  /// **'الأقصر'**
  String get shortest;

  /// No description provided for @longest.
  ///
  /// In ar, this message translates to:
  /// **'الأطول'**
  String get longest;

  /// No description provided for @allSurahs.
  ///
  /// In ar, this message translates to:
  /// **'جميع السور'**
  String get allSurahs;

  /// No description provided for @meccanSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور المكية'**
  String get meccanSurahs;

  /// No description provided for @medinanSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور المدنية'**
  String get medinanSurahs;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @downloading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التنزيل...'**
  String get downloading;

  /// No description provided for @processing.
  ///
  /// In ar, this message translates to:
  /// **'جاري المعالجة...'**
  String get processing;

  /// No description provided for @searching.
  ///
  /// In ar, this message translates to:
  /// **'جاري البحث...'**
  String get searching;

  /// No description provided for @pleaseWait.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء الانتظار...'**
  String get pleaseWait;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get inProgress;

  /// No description provided for @paused.
  ///
  /// In ar, this message translates to:
  /// **'متوقف مؤقتاً'**
  String get paused;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get errorOccurred;

  /// No description provided for @errorLoading.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء التحميل'**
  String get errorLoading;

  /// No description provided for @errorLoadingSurahs.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل السور'**
  String get errorLoadingSurahs;

  /// No description provided for @errorLoadingAyahs.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الآيات'**
  String get errorLoadingAyahs;

  /// No description provided for @errorLoadingAudio.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الملف الصوتي'**
  String get errorLoadingAudio;

  /// No description provided for @errorLoadingTafsir.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل التفسير'**
  String get errorLoadingTafsir;

  /// No description provided for @errorNoInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get errorNoInternet;

  /// No description provided for @errorNoInternetDesc.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصالك بالإنترنت وحاول مرة أخرى'**
  String get errorNoInternetDesc;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الاتصال بالشبكة'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الخادم'**
  String get errorServer;

  /// No description provided for @errorTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال'**
  String get errorTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In ar, this message translates to:
  /// **'خطأ غير متوقع'**
  String get errorUnknown;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get tryAgain;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @noSurahs.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سور'**
  String get noSurahs;

  /// No description provided for @noAyahs.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات'**
  String get noAyahs;

  /// No description provided for @noFavorites.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفضلات'**
  String get noFavorites;

  /// No description provided for @noBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علامات مرجعية'**
  String get noBookmarks;

  /// No description provided for @noHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سجل'**
  String get noHistory;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على نتائج'**
  String get noSearchResults;

  /// No description provided for @emptyFavorites.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المفضلات فارغة'**
  String get emptyFavorites;

  /// No description provided for @emptyBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'قائمة العلامات فارغة'**
  String get emptyBookmarks;

  /// No description provided for @progress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم'**
  String get progress;

  /// No description provided for @statistics.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get statistics;

  /// No description provided for @readingProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم القراءة'**
  String get readingProgress;

  /// No description provided for @pagesRead.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات المقروءة'**
  String get pagesRead;

  /// No description provided for @ayahsRead.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المقروءة'**
  String get ayahsRead;

  /// No description provided for @timeSpent.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المستغرق'**
  String get timeSpent;

  /// No description provided for @completionPercentage.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإتمام'**
  String get completionPercentage;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get thisMonth;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stop;

  /// No description provided for @resume.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get resume;

  /// No description provided for @repeat.
  ///
  /// In ar, this message translates to:
  /// **'تكرار'**
  String get repeat;

  /// No description provided for @repeatOne.
  ///
  /// In ar, this message translates to:
  /// **'تكرار الآية'**
  String get repeatOne;

  /// No description provided for @repeatRange.
  ///
  /// In ar, this message translates to:
  /// **'تكرار النطاق'**
  String get repeatRange;

  /// No description provided for @repeatSurah.
  ///
  /// In ar, this message translates to:
  /// **'تكرار السورة'**
  String get repeatSurah;

  /// No description provided for @noRepeat.
  ///
  /// In ar, this message translates to:
  /// **'بدون تكرار'**
  String get noRepeat;

  /// No description provided for @speed.
  ///
  /// In ar, this message translates to:
  /// **'السرعة'**
  String get speed;

  /// No description provided for @playbackSpeed.
  ///
  /// In ar, this message translates to:
  /// **'سرعة التشغيل'**
  String get playbackSpeed;

  /// No description provided for @reciter.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get reciter;

  /// No description provided for @selectReciter.
  ///
  /// In ar, this message translates to:
  /// **'اختر القارئ'**
  String get selectReciter;

  /// No description provided for @downloadAudio.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الصوت'**
  String get downloadAudio;

  /// No description provided for @deleteAudio.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصوت'**
  String get deleteAudio;

  /// No description provided for @audioDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'تم تحميل الصوت'**
  String get audioDownloaded;

  /// No description provided for @tafsirMuyassar.
  ///
  /// In ar, this message translates to:
  /// **'التفسير الميسر'**
  String get tafsirMuyassar;

  /// No description provided for @tafsirSaadi.
  ///
  /// In ar, this message translates to:
  /// **'تفسير السعدي'**
  String get tafsirSaadi;

  /// No description provided for @tafsirTabari.
  ///
  /// In ar, this message translates to:
  /// **'تفسير الطبري'**
  String get tafsirTabari;

  /// No description provided for @selectTafsir.
  ///
  /// In ar, this message translates to:
  /// **'اختر التفسير'**
  String get selectTafsir;

  /// No description provided for @showTafsir.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفسير'**
  String get showTafsir;

  /// No description provided for @hideTafsir.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التفسير'**
  String get hideTafsir;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @fontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get fontSize;

  /// No description provided for @fontFamily.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخط'**
  String get fontFamily;

  /// No description provided for @textSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم النص'**
  String get textSize;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get lightMode;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'السمة'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل الإشعارات'**
  String get disableNotifications;

  /// No description provided for @autoScroll.
  ///
  /// In ar, this message translates to:
  /// **'التمرير التلقائي'**
  String get autoScroll;

  /// No description provided for @addBookmark.
  ///
  /// In ar, this message translates to:
  /// **'إضافة علامة مرجعية'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In ar, this message translates to:
  /// **'إزالة العلامة المرجعية'**
  String get removeBookmark;

  /// No description provided for @addToFavorites.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للمفضلة'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المفضلة'**
  String get removeFromFavorites;

  /// No description provided for @shareVerse.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الآية'**
  String get shareVerse;

  /// No description provided for @copyVerse.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الآية'**
  String get copyVerse;

  /// No description provided for @playVerse.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الآية'**
  String get playVerse;

  /// No description provided for @showTafsirVerse.
  ///
  /// In ar, this message translates to:
  /// **'عرض تفسير الآية'**
  String get showTafsirVerse;

  /// No description provided for @addNote.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة'**
  String get deleteNote;

  /// No description provided for @success.
  ///
  /// In ar, this message translates to:
  /// **'نجح'**
  String get success;

  /// No description provided for @bookmarkAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة العلامة المرجعية'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة العلامة المرجعية'**
  String get bookmarkRemoved;

  /// No description provided for @addedToFavorites.
  ///
  /// In ar, this message translates to:
  /// **'أضيف للمفضلة'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In ar, this message translates to:
  /// **'أزيل من المفضلة'**
  String get removedFromFavorites;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات'**
  String get settingsSaved;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get confirmDeleteMessage;

  /// No description provided for @confirmClear.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد المسح'**
  String get confirmClear;

  /// No description provided for @confirmClearHistory.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مسح السجل؟'**
  String get confirmClearHistory;

  /// No description provided for @confirmClearBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مسح جميع العلامات؟'**
  String get confirmClearBookmarks;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن مثاني'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In ar, this message translates to:
  /// **'المطور'**
  String get developer;

  /// No description provided for @contact.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contact;

  /// No description provided for @rateApp.
  ///
  /// In ar, this message translates to:
  /// **'قيّم التطبيق'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In ar, this message translates to:
  /// **'شارك التطبيق'**
  String get shareApp;

  /// No description provided for @help.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get help;

  /// No description provided for @privacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get privacy;

  /// No description provided for @terms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get terms;

  /// No description provided for @minute.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get minute;

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق'**
  String get minutes;

  /// No description provided for @hour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات'**
  String get hours;

  /// No description provided for @day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get day;

  /// No description provided for @days.
  ///
  /// In ar, this message translates to:
  /// **'أيام'**
  String get days;

  /// No description provided for @week.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع'**
  String get week;

  /// No description provided for @weeks.
  ///
  /// In ar, this message translates to:
  /// **'أسابيع'**
  String get weeks;

  /// No description provided for @month.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get month;

  /// No description provided for @months.
  ///
  /// In ar, this message translates to:
  /// **'أشهر'**
  String get months;

  /// No description provided for @tip.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة'**
  String get tip;

  /// No description provided for @didYouKnow.
  ///
  /// In ar, this message translates to:
  /// **'هل تعلم؟'**
  String get didYouKnow;

  /// No description provided for @tapToPlayAudio.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتشغيل الصوت'**
  String get tapToPlayAudio;

  /// No description provided for @longPressForOptions.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً للخيارات'**
  String get longPressForOptions;

  /// No description provided for @swipeToNavigate.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للتنقل'**
  String get swipeToNavigate;

  /// No description provided for @doubleTapToBookmark.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرتين للعلامة المرجعية'**
  String get doubleTapToBookmark;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
