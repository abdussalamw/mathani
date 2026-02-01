import 'package:just_audio/just_audio.dart';

/// خدمة تشغيل الصوت للقرآن الكريم
class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  String? _currentUrl;
  
  /// تشغيل ملف صوتي من URL
  Future<void> play(String url) async {
    try {
      if (_currentUrl != url) {
        await stop();
        _currentUrl = url;
        await _audioPlayer.setUrl(url);
      }
      
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// إيقاف التشغيل مؤقتاً
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      rethrow;
    }
  }
  
  /// استئناف التشغيل
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// إيقاف التشغيل نهائياً
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentUrl = null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// الحصول على حالة التشغيل
  bool get isPlaying => _isPlaying;
  
  /// الحصول على URL الحالي
  String? get currentUrl => _currentUrl;
  
  /// تحديد مستوى الصوت (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// الاستماع لموضع التشغيل
  Stream<Duration> get onPositionChanged => _audioPlayer.positionStream;
  
  /// الاستماع لمدة الملف
  Stream<Duration?> get onDurationChanged => _audioPlayer.durationStream;
  
  /// تنظيف الموارد
  void dispose() {
    _audioPlayer.dispose();
  }
}
