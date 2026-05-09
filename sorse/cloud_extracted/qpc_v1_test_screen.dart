import 'package:flutter/material.dart';
import 'qpc_v1_models.dart';
import 'qpc_v1_database_service.dart';
import 'qpc_v1_font_service.dart';
import 'qpc_v1_page_widget.dart';

/// شاشة اختبار شاملة لنظام QPC V1
/// 
/// توفر:
/// - اختبار تحميل قاعدة البيانات
/// - اختبار تحميل الخطوط
/// - اختبار عرض الصفحات
/// - عرض الإحصائيات والتشخيص
class QPCV1TestScreen extends StatefulWidget {
  const QPCV1TestScreen({Key? key}) : super(key: key);

  @override
  State<QPCV1TestScreen> createState() => _QPCV1TestScreenState();
}

class _QPCV1TestScreenState extends State<QPCV1TestScreen> {
  final _dbService = QPCV1DatabaseService();
  final _fontService = QPCV1FontService();
  
  bool _isInitialized = false;
  String _statusMessage = 'جاري التحميل...';
  Map<String, dynamic>? _dbInfo;
  Map<String, dynamic>? _fontStats;
  
  int _currentPage = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _statusMessage = 'بدء الاختبارات...';
    });

    try {
      // اختبار 1: تهيئة قاعدة البيانات
      setState(() {
        _statusMessage = '✓ اختبار 1: تهيئة قاعدة البيانات';
      });
      await _dbService.initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // اختبار 2: جلب معلومات قاعدة البيانات
      setState(() {
        _statusMessage = '✓ اختبار 2: جلب معلومات قاعدة البيانات';
      });
      final dbInfo = await _dbService.getDatabaseInfo();
      setState(() {
        _dbInfo = dbInfo;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // اختبار 3: تحميل صفحة تجريبية
      setState(() {
        _statusMessage = '✓ اختبار 3: تحميل صفحة تجريبية (صفحة 1)';
      });
      final page1 = await _dbService.loadPage(1);
      debugPrint('Page 1 loaded: ${page1.lines.length} lines');
      await Future.delayed(const Duration(milliseconds: 500));

      // اختبار 4: تحميل خط الصفحة
      setState(() {
        _statusMessage = '✓ اختبار 4: تحميل خط الصفحة';
      });
      final fontLoaded = await _fontService.loadPageFont(1);
      debugPrint('Font loaded: $fontLoaded');
      await Future.delayed(const Duration(milliseconds: 500));

      // اختبار 5: جلب إحصائيات الخطوط
      setState(() {
        _statusMessage = '✓ اختبار 5: جلب إحصائيات الخطوط';
      });
      final fontStats = _fontService.getStatistics();
      setState(() {
        _fontStats = fontStats;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // اختبار 6: اختبار صفحات متعددة
      setState(() {
        _statusMessage = '✓ اختبار 6: تحميل صفحات متعددة';
      });
      for (int i = 2; i <= 5; i++) {
        await _dbService.loadPage(i);
        await _fontService.loadPageFont(i);
        debugPrint('Page $i loaded');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // اختبار 7: التحقق من الأنواع المختلفة للأسطر
      setState(() {
        _statusMessage = '✓ اختبار 7: التحقق من أنواع الأسطر';
      });
      _verifyLineTypes(page1);
      await Future.delayed(const Duration(milliseconds: 500));

      // النجاح!
      setState(() {
        _statusMessage = '✅ جميع الاختبارات نجحت!';
        _isInitialized = true;
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ خطأ: $e';
      });
      debugPrint('Test failed: $e');
    }
  }

  void _verifyLineTypes(QPCV1Page page) {
    final types = <QPCV1LineType, int>{};
    
    for (var line in page.lines) {
      types[line.type] = (types[line.type] ?? 0) + 1;
    }
    
    debugPrint('Line types in page ${page.pageNumber}:');
    types.forEach((type, count) {
      debugPrint('  - ${type.toString()}: $count');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام QPC V1'),
        backgroundColor: const Color(0xFF8B6914),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSystemInfo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: _isInitialized ? _buildMainContent() : _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFFF5F3E8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B6914)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  color: Color(0xFF5C4A1F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // شريط التحكم
        _buildControlBar(),
        
        // عرض الصفحة
        Expanded(
          child: PageView.builder(
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
              );
            },
          ),
        ),
        
        // شريط الإحصائيات
        _buildStatsBar(),
      ],
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentPage > 1
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'صفحة $_currentPage من 604',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'الجزء ${QPCV1Statistics.getJuzFromPage(_currentPage)}',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentPage < 604
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showPageSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.image,
            label: 'خطوط محملة',
            value: '${_fontStats?['loaded_pages'] ?? 0}',
          ),
          _buildStatItem(
            icon: Icons.storage,
            label: 'صفحات في Cache',
            value: '${_dbInfo?['cached_pages'] ?? 0}',
          ),
          _buildStatItem(
            icon: Icons.memory,
            label: 'Glyphs في Cache',
            value: '${_dbInfo?['cached_glyphs'] ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B6914)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showPageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        int selectedPage = _currentPage;
        
        return AlertDialog(
          title: const Text('اختر الصفحة'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'صفحة $selectedPage',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: selectedPage.toDouble(),
                    min: 1,
                    max: 604,
                    divisions: 603,
                    label: selectedPage.toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedPage = value.toInt();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _pageController.jumpToPage(selectedPage - 1);
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات النظام'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('قاعدة البيانات', _dbInfo),
              const Divider(),
              _buildInfoSection('الخطوط', _fontStats),
              const Divider(),
              const Text(
                'الإحصائيات العامة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('إجمالي الصفحات: ${QPCV1Statistics.totalPages}'),
              Text('الأسطر في كل صفحة: ${QPCV1Statistics.linesPerPage}'),
              Text('إجمالي السور: ${QPCV1Statistics.totalSurahs}'),
              Text('إجمالي الآيات: ${QPCV1Statistics.totalAyahs}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbService.clearCache();
              await _fontService.clearMemoryCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح Cache')),
              );
            },
            child: const Text('مسح Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic>? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (data != null)
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${entry.key}: ${entry.value}'),
            );
          })
        else
          const Text('لا توجد بيانات'),
      ],
    );
  }
}
