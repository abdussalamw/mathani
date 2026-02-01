import 'package:flutter/material.dart';
import 'package:mathani/data/services/qcf4_font_downloader.dart';

/// شاشة اختبار تحميل خطوط QCF4
class FontTestScreen extends StatefulWidget {
  const FontTestScreen({Key? key}) : super(key: key);

  @override
  State<FontTestScreen> createState() => _FontTestScreenState();
}

class _FontTestScreenState extends State<FontTestScreen> {
  bool _isLoading = false;
  bool _fontLoaded = false;
  String _status = 'جاهز للاختبار';
  int _cacheSize = 0;
  
  Future<void> _testFont() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري تحميل خط الصفحة الأولى...';
    });
    
    try {
      // تحميل خط الصفحة الأولى
      final loaded = await QCF4FontDownloader.loadPageFont(1);
      
      if (loaded) {
        setState(() {
          _fontLoaded = true;
          _status = 'تم تحميل الخط بنجاح! ✅';
        });
        
        // الحصول على حجم Cache
        final size = await QCF4FontDownloader.getCacheSize();
        setState(() {
          _cacheSize = size;
        });
      } else {
        setState(() {
          _status = 'فشل تحميل الخط ❌';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _clearCache() async {
    await QCF4FontDownloader.clearCache();
    setState(() {
      _fontLoaded = false;
      _cacheSize = 0;
      _status = 'تم مسح Cache';
    });
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار خطوط QCF4'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة
              Icon(
                _fontLoaded ? Icons.check_circle : Icons.download,
                size: 80,
                color: _fontLoaded ? Colors.green : Colors.blue,
              ),
              
              const SizedBox(height: 24),
              
              // الحالة
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // حجم Cache
              if (_cacheSize > 0)
                Text(
                  'حجم Cache: ${_formatBytes(_cacheSize)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // نص تجريبي بالخط المحمل
              if (_fontLoaded)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    border: Border.all(color: Colors.brown.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    style: TextStyle(
                      fontFamily: 'QCF4_001',
                      fontSize: 28,
                      color: Colors.black87,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // زر الاختبار
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFont,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isLoading ? 'جاري التحميل...' : 'اختبار تحميل الخط'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // زر مسح Cache
              if (_fontLoaded)
                TextButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('مسح Cache'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // معلومات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ℹ️ معلومات الاختبار:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• يتم تحميل خط QCF4_001.woff من GitHub'),
                    Text('• الخط يُحفظ في Cache للاستخدام لاحقاً'),
                    Text('• حجم الخط الواحد: ~80-100 KB'),
                    Text('• إجمالي 605 خط (604 صفحة + بسملة)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
