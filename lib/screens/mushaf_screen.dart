
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/page_font_manager.dart';
import '../providers/mushaf_metadata_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import 'mushaf_selection_screen.dart';

class MushafScreen extends StatefulWidget {
  final int? initialSurahNumber;
  const MushafScreen({Key? key, this.initialSurahNumber}) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  bool _showBars = true;
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  Map<String, dynamic> _qcfCodes = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0); // Default, will update
    _loadQcfCodes();
    
    // ... existing init ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quran = context.read<QuranProvider>();
      quran.loadFullQuran().then((_) {
         if (widget.initialSurahNumber != null) {
            // منطق الانتقال للسورة المحددة
            _navigateToSurah(widget.initialSurahNumber!);
         }
      });
    });
  }
  
  void _navigateToSurah(int surahNumber) {
    // خريطة صفحات بداية السور (تقريبية لمصحف المدينة)
    // في الوضع المثالي، هذه البيانات تأتي من قاعدة البيانات
    final Map<int, int> surahToPage = {
      1: 1,   // الفاتحة
      2: 2,   // البقرة
      3: 50,  // آل عمران
      // ... يمكن التوسع فيها لاحقاً أو جلبها ديناميكياً
    };

    final targetPage = surahToPage[surahNumber] ?? 1;
    
    if (_pageController.hasClients) {
       _pageController.jumpToPage(targetPage - 1);
    } else {
       // إذا لم يكن جاهزاً، نحاول بعد قليل
       Future.delayed(const Duration(milliseconds: 300), () {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetPage - 1);
          }
       });
    }
  }
  
  void _toggleBars() {
    setState(() => _showBars = !_showBars);
  }

  Future<void> _loadQcfCodes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran_qcf2_codes.json');
      setState(() {
        _qcfCodes = json.decode(jsonString);
      });
    } catch (e) {
      debugPrint('Error loading QCF codes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
  @override
  Widget build(BuildContext context) {
    return Consumer3<QuranProvider, SettingsProvider, MushafMetadataProvider>(
      builder: (context, quran, settings, mushafMeta, _) {
          final isQcf = mushafMeta.currentMushafId.contains('qcf') || mushafMeta.currentMushafId.contains('image');
          
          // مصغي لقفزات الفهرس
          if (quran.jumpToSurahNumber != null) {
             // نقوم بتنفيذ القفزة ثم "نستهلك" الأمر لكي لا يتكرر
             final surahNum = quran.jumpToSurahNumber!;
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 _navigateToSurah(surahNum);
                 quran.clearJump();
             });
          }

          return Scaffold(
             backgroundColor: settings.isDarkMode ? AppColors.darkBackground : const Color(0xFFFFF8E1), // لون ورقي فاتح
             body: Stack(
               children: [
                 // طبقة المحتوى الرئيسي
                 GestureDetector(
                   onTap: _toggleBars,
                   // إذا كان المصحف صور أو QCF نستخدم العرض الصفحي، وإلا القائمة العمودية
                   // حالياً سنجعل كل المصاحف "صفحية" لأنها أجمل وأقرب للواقع
                   // لكن المصحف الأول سنتركه "سردي" كما هو للاحتياط
                   child: isQcf 
                     ? _buildPaginatedView(quran, mushafMeta, settings) // تم تغيير الاسم
                     : _buildStandardView(quran, settings),
                 ),

                 // الشريط العلوي
                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 300),
                   top: _showBars ? 0 : -100,
                   left: 0,
                   right: 0,
                   child: AppBar(
                     backgroundColor: (settings.isDarkMode ? AppColors.darkSurface : AppColors.white).withOpacity(0.95),
                     elevation: 4,
                     title: Text(
                       'المصحف الشريف',
                       style: TextStyle(
                         color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown,
                         fontFamily: 'Tajawal',
                         fontWeight: FontWeight.bold
                       )
                     ),
                     centerTitle: true,
                     iconTheme: IconThemeData(
                       color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown
                     ),
                   ),
                 ),

                 // الشريط السفلي (تم حذف التنقل منه لأن الـ MainShell يقوم بالواجب)
                 // سنبقي عليه كشريط أدوات قراءة فقط
                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 300),
                   bottom: _showBars ? 0 : -100,
                   left: 0,
                   right: 0,
                   child: Container(
                     decoration: BoxDecoration(
                       color: (settings.isDarkMode ? AppColors.darkSurface : AppColors.white).withOpacity(0.95),
                       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
                     ),
                     padding: const EdgeInsets.symmetric(vertical: 8),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
                         IconButton(icon: const Icon(Icons.library_books), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MushafSelectionScreen()))),
                       ],
                     ),
                   ),
                 ),
               ],
             )
          );
      }
    );
  }
  
  // عرض المصحف العادي (قائمة)
  Widget _buildStandardView(QuranProvider quran, SettingsProvider settings) {
      if (quran.isLoading) return const Center(child: CircularProgressIndicator());
      // تأكد من تحميل الكل
      if (quran.ayahs.isEmpty) {
         quran.loadFullQuran();
         return const Center(child: CircularProgressIndicator());
      }
      
      return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100), 
              itemCount: quran.mappedSurahs.length, // عدد السور
              itemBuilder: (context, index) {
                   final surah = quran.mappedSurahs[index];
                   final ayahs = quran.ayahsBySurah[surah.number] ?? [];
                   if (ayahs.isEmpty) return const SizedBox(); // لم يتم التحميل بعد

                   return _buildSurahItem(surah, ayahs, settings);
              }
      );
  }

  // العرض الصفحي (بديل للـ QCF المعقد) 
  // يستخدم النص العثماني ويرتبه في صفحات (محاكاة)
  Widget _buildPaginatedView(QuranProvider quran, MushafMetadataProvider mushafMeta, SettingsProvider settings) {
      // هنا نستخدم حيلة ذكية: بدلاً من الاعتماد على ملفات غير موجودة
      // سنقوم بعرض "صفحات" تحتوي على الآيات النصية
      // سنفترض أن كل سورة تبدأ في صفحة جديدة للتبسيط حالياً
      // أو نستخدم رقم الصفحة الموجود في الآية (وهو موجود فعلاً في القاعدة!)

      if (quran.isLoading) return const Center(child: CircularProgressIndicator());
      if (quran.ayahs.isEmpty) {
           quran.loadFullQuran(); 
           return const Center(child: CircularProgressIndicator());
      }

      return PageView.builder(
        controller: _pageController,
        reverse: true,
        itemCount: 604, // مصحف المدينة
        itemBuilder: (context, index) {
           final pageNum = index + 1;
           return FutureBuilder<List<dynamic>>(
             future: quran.getAyahsForPage(pageNum), // دالة موجودة في البروفايدر
             builder: (context, snapshot) {
               if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return const Center(child: CircularProgressIndicator());
               }
               
               final pageAyahs = snapshot.data!;
               // نحتاج معرفة السور الموجودة في هذه الصفحة لرسم اسم السورة والبسملة
               // سنقوم بتجميع الآيات حسب السورة داخل الصفحة
               
               return Container(
                 margin: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: settings.isDarkMode ? AppColors.darkSurface : Colors.white,
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                   border: Border.all(color: AppColors.golden, width: 2)
                 ),
                 child: SingleChildScrollView(
                   child: Column(
                     children: [
                       // رقم الصفحة واسم السورة (اختياري)
                       Text('صفحة $pageNum', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
                       const SizedBox(height: 10),
                       
                       // النص القرآني
                       SelectableText.rich(
                         TextSpan(
                           children: pageAyahs.map((ayah) {
                              // التحقق من بداية السورة لرسم البسملة (بشكل مبسط)
                              final isFirstAyah = ayah.ayahNumber == 1;
                              
                              return TextSpan(
                                children: [
                                  if (isFirstAyah) 
                                     const TextSpan(text: '\n\n﷽\n\n', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold)),
                                     
                                  TextSpan(
                                    text: ayah.textUthmani + ' ',
                                    style: TextStyle(
                                      fontFamily: 'Amiri', // خط عثماني موثوق
                                      fontSize: settings.fontSize * 1.1, // تكبير قليلاً
                                      height: 1.8,
                                      color: settings.isDarkMode ? AppColors.darkText : Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '﴿${ayah.ayahNumber}﴾ ',
                                    style: TextStyle(
                                        color: AppColors.golden,
                                        fontSize: settings.fontSize,
                                        fontFamily: 'Amiri',
                                    ),
                                  ),
                                ],
                              );
                           }).toList(),
                         ),
                         textAlign: TextAlign.justify,
                         textDirection: TextDirection.rtl,
                       ),
                     ],
                   ),
                 ),
               );
             }
           );
        },
      );
  }

  Widget _buildBottomNavItem(BuildContext context, IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.greyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.greyMedium,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
