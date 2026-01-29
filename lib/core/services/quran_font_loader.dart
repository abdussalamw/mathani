// ===================================================================
// lib/core/services/quran_font_loader.dart
// ===================================================================
// خدمة لإدارة تحميل واستخدام خطوط QCF2

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mathani/core/services/fonts_downloader_service.dart';

class QuranFontLoader {
  static final QuranFontLoader _instance = QuranFontLoader._internal();
  static QuranFontLoader get instance => _instance;
  
  QuranFontLoader._internal();
  
  // Cache للخطوط المحملة لتحسين الأداء
  final Map<int, ByteData> _fontCache = {};
  
  /// تحميل خط QCF2 لصفحة معينة
  Future<String?> loadFontForPage(int pageNumber) async {
    try {
      // الحصول على مسار الخط
      final fontPath = await FontsDownloaderService.instance
          .getQCF2FontPath(pageNumber);
      
      final fontFile = File(fontPath);
      
      if (!await fontFile.exists()) {
        print('الخط غير موجود للصفحة $pageNumber');
        return null;
      }
      
      // قراءة الخط وتسجيله
      final fontData = await fontFile.readAsBytes();
      final fontLoader = FontLoader('QCF_P${pageNumber.toString().padLeft(3, '0')}');
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      return 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      print('خطأ في تحميل الخط للصفحة $pageNumber: $e');
      return null;
    }
  }
  
  /// تحميل مجموعة من الخطوط مسبقاً (للصفحات المجاورة)
  Future<void> preloadFontsForPages(List<int> pages) async {
    for (final page in pages) {
      await loadFontForPage(page);
    }
  }
  
  /// الحصول على اسم العائلة الخطية لصفحة معينة
  String getFontFamilyForPage(int pageNumber) {
    return 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
  }
  
  /// مسح ذاكرة التخزين المؤقت
  void clearCache() {
    _fontCache.clear();
  }
}

// ===================================================================
// lib/presentation/widgets/quran_text_widget.dart
// ===================================================================
// Widget لعرض النص القرآني بالخط المناسب

import 'package:flutter/material.dart';
import 'package:mathani/core/services/quran_font_loader.dart';
import 'package:mathani/core/constants/app_colors.dart';

class QuranTextWidget extends StatefulWidget {
  final String text;
  final int pageNumber;
  final double fontSize;
  final Color? textColor;
  final TextAlign textAlign;
  final double lineHeight;
  final bool useQCF2; // استخدام QCF2 أو الخط الاحتياطي
  
  const QuranTextWidget({
    Key? key,
    required this.text,
    required this.pageNumber,
    this.fontSize = 28,
    this.textColor,
    this.textAlign = TextAlign.justify,
    this.lineHeight = 2.2,
    this.useQCF2 = true,
  }) : super(key: key);

  @override
  State<QuranTextWidget> createState() => _QuranTextWidgetState();
}

class _QuranTextWidgetState extends State<QuranTextWidget> {
  String? _fontFamily;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.useQCF2) {
      _loadFont();
    } else {
      setState(() {
        _fontFamily = 'Amiri'; // خط احتياطي
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadFont() async {
    final fontLoader = QuranFontLoader.instance;
    final fontFamily = await fontLoader.loadFontForPage(widget.pageNumber);
    
    setState(() {
      _fontFamily = fontFamily ?? 'Amiri'; // احتياطي
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    
    return Text(
      widget.text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: widget.fontSize,
        color: widget.textColor ?? AppColors.darkBrown,
        height: widget.lineHeight,
        letterSpacing: 0.5,
      ),
      textAlign: widget.textAlign,
      textDirection: TextDirection.rtl,
    );
  }
}

// ===================================================================
// lib/presentation/widgets/ayah_widget.dart
// ===================================================================
// Widget لعرض آية واحدة مع رقمها

import 'package:flutter/material.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/presentation/widgets/quran_text_widget.dart';
import 'package:mathani/core/constants/app_colors.dart';

class AyahWidget extends StatelessWidget {
  final Ayah ayah;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const AyahWidget({
    Key? key,
    required this.ayah,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.golden.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.golden, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // النص القرآني
            QuranTextWidget(
              text: ayah.text,
              pageNumber: ayah.page,
              fontSize: 28,
              useQCF2: true,
            ),
            
            const SizedBox(height: 8),
            
            // رقم الآية داخل دائرة ذهبية
            Align(
              alignment: Alignment.centerLeft,
              child: _buildAyahNumber(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAyahNumber() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.golden, width: 2),
        color: AppColors.white,
      ),
      child: Center(
        child: Text(
          _convertToArabicNumbers(ayah.ayahNumber),
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            color: AppColors.golden,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // تحويل الأرقام للعربية
  String _convertToArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }
}

// ===================================================================
// lib/presentation/widgets/surah_header_widget.dart
// ===================================================================
// رأس السورة مع البسملة

import 'package:flutter/material.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SurahHeaderWidget extends StatelessWidget {
  final Surah surah;
  
  const SurahHeaderWidget({
    Key? key,
    required this.surah,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.golden.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // اسم السورة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.golden, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              surah.nameArabic,
              style: GoogleFonts.amiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // معلومات السورة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.greyDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.golden,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${surah.numberOfAyahs} آية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.greyDark,
                ),
              ),
            ],
          ),
          
          // البسملة (إلا التوبة)
          if (surah.number != 1 && surah.number != 9) ...[
            const SizedBox(height: 24),
            _buildBasmala(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBasmala() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: AppColors.golden, width: 1),
          bottom: BorderSide(color: AppColors.golden, width: 1),
        ),
      ),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 24,
          color: AppColors.darkBrown,
          fontWeight: FontWeight.w600,
          height: 1.8,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ===================================================================
// مثال استخدام في MushafScreen
// ===================================================================

/*
class MushafScreen extends StatefulWidget {
  final int initialSurah;
  
  const MushafScreen({
    Key? key,
    this.initialSurah = 1,
  }) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late QuranProvider _quranProvider;
  
  @override
  void initState() {
    super.initState();
    _quranProvider = Provider.of<QuranProvider>(context, listen: false);
    _loadSurah();
  }
  
  Future<void> _loadSurah() async {
    await _quranProvider.loadSurah(widget.initialSurah);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.currentSurah == null || provider.currentAyahs.isEmpty) {
            return const Center(child: Text('لا توجد بيانات'));
          }
          
          return CustomScrollView(
            slivers: [
              // رأس السورة
              SliverToBoxAdapter(
                child: SurahHeaderWidget(
                  surah: provider.currentSurah!,
                ),
              ),
              
              // قائمة الآيات
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ayah = provider.currentAyahs[index];
                    return AyahWidget(
                      ayah: ayah,
                      onTap: () {
                        // عند النقر على آية
                      },
                    );
                  },
                  childCount: provider.currentAyahs.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
*/