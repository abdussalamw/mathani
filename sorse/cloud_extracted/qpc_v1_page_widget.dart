import 'package:flutter/material.dart';
import 'qpc_v1_models.dart';
import 'qpc_v1_database_service.dart';
import 'qpc_v1_font_service.dart';

/// Widget محسّن لعرض صفحة من مصحف QPC V1
/// 
/// يوفر:
/// - عرض احترافي للصفحة بكل تفاصيلها
/// - دعم رؤوس السور والبسملة
/// - تحميل تلقائي للخطوط
/// - معالجة الأخطاء الشاملة
class QPCV1PageWidget extends StatefulWidget {
  final int pageNumber;
  final VoidCallback? onPageLoaded;
  final VoidCallback? onPageError;
  
  const QPCV1PageWidget({
    Key? key,
    required this.pageNumber,
    this.onPageLoaded,
    this.onPageError,
  }) : super(key: key);

  @override
  State<QPCV1PageWidget> createState() => _QPCV1PageWidgetState();
}

class _QPCV1PageWidgetState extends State<QPCV1PageWidget> {
  final _dbService = QPCV1DatabaseService();
  final _fontService = QPCV1FontService();
  
  QPCV1Page? _page;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void didUpdateWidget(QPCV1PageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. تحميل بيانات الصفحة
      final page = await _dbService.loadPage(widget.pageNumber);
      
      // 2. تحميل الخط المطلوب
      final fontLoaded = await _fontService.loadPageFont(widget.pageNumber);
      
      if (!fontLoaded) {
        throw Exception('فشل تحميل الخط للصفحة ${widget.pageNumber}');
      }
      
      // 3. تحميل مسبق للصفحات المحيطة (في الخلفية)
      _fontService.preloadSurroundingPages(widget.pageNumber);
      
      setState(() {
        _page = page;
        _isLoading = false;
      });
      
      widget.onPageLoaded?.call();
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      widget.onPageError?.call();
      debugPrint('Error loading page ${widget.pageNumber}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_page == null) {
      return _buildEmptyWidget();
    }

    return _buildPageContent();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: const Color(0xFFF5F3E8), // لون ورق المصحف
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B6914)),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الصفحة...',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                color: Color(0xFF5C4A1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFFF5F3E8),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في تحميل الصفحة',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPage,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      color: const Color(0xFFF5F3E8),
      child: const Center(
        child: Text(
          'لا توجد بيانات للعرض',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    return Container(
      color: const Color(0xFFF5F3E8),
      child: Column(
        children: [
          // رقم الصفحة والجزء في الأعلى
          _buildPageHeader(),
          
          // محتوى الصفحة
          Expanded(
            child: _buildLinesContent(),
          ),
          
          // رقم الصفحة في الأسفل
          _buildPageFooter(),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF8B6914).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الجزء ${_page!.juz}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: Color(0xFF8B6914),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_page!.surahNumber != null)
            Text(
              _getSurahName(_page!.surahNumber!),
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: Color(0xFF8B6914),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: _page!.lines.map((line) => _buildLine(line)).toList(),
      ),
    );
  }

  Widget _buildLine(QPCV1Line line) {
    final fontFamily = _fontService.getFontFamilyForPage(widget.pageNumber);
    
    // تحديد الـ Style بناءً على نوع السطر
    TextStyle textStyle;
    TextAlign textAlign;
    EdgeInsets padding;
    
    switch (line.type) {
      case QPCV1LineType.surahName:
        textStyle = TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          color: const Color(0xFF8B6914),
          height: 2.0,
        );
        textAlign = TextAlign.center;
        padding = const EdgeInsets.symmetric(vertical: 16);
        break;
        
      case QPCV1LineType.basmala:
        textStyle = TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          color: const Color(0xFF000000),
          height: 2.0,
        );
        textAlign = TextAlign.center;
        padding = const EdgeInsets.symmetric(vertical: 12);
        break;
        
      case QPCV1LineType.ayahText:
        textStyle = TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          color: const Color(0xFF000000),
          height: 1.8,
          letterSpacing: 0,
        );
        textAlign = TextAlign.justify;
        padding = const EdgeInsets.symmetric(vertical: 4);
        break;
        
      case QPCV1LineType.empty:
        return const SizedBox(height: 8);
    }
    
    return Container(
      padding: padding,
      child: Text(
        line.text,
        style: textStyle,
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildPageFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B6914).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Text(
          '${widget.pageNumber}',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            color: Color(0xFF8B6914),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getSurahName(int surahNumber) {
    const surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
      'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
      'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص',
      'الزمر', 'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق', 'الذاريات', 'الطور',
      'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر',
      'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم',
      'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن', 'المزمل',
      'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق',
      'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى',
      'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون',
      'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس'
    ];
    
    if (surahNumber >= 1 && surahNumber <= 114) {
      return 'سورة ${surahNames[surahNumber - 1]}';
    }
    return '';
  }
}
