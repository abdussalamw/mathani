import '../../core/utils/async_work_pool.dart';

import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class LocalTafsirService extends ChangeNotifier {
  static final LocalTafsirService _instance = LocalTafsirService._internal();
  static LocalTafsirService get instance => _instance;
  LocalTafsirService._internal();

  bool _isLoaded = false;
  Future<void>? _loadFuture;
  int _generation = 0;
  final Map<String, String> _tafsirMap = {};
  String? _lastError;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isLoaded => _isLoaded;
  int get totalEntries => _tafsirMap.length;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get lastError => _lastError;

  static const String tafsirUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tafseerMouaser_v03.csv';
  static const String fileName = 'tafseerMouaser_v03.csv';

  Future<void> init() async {
    await loadTafsirData();
  }

  Future<bool> isTafsirDownloaded() async {
    if (kIsWeb) return false;
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(appDir.path, 'tafsir', fileName));
    return await file.exists();
  }

  final _downloads = AsyncWorkPool<String, void>();
  Future<void> downloadAndExtractTafsir({Function(double)? onProgress}) =>
      _downloads.run(fileName, () => _download(onProgress));

  Future<void> _download(Function(double)? onProgress) async {
    if (kIsWeb) return;
    File? tempFile;
    final client = http.Client();
    try {
      _lastError = null;
      _isDownloading = true;
      _downloadProgress = 0.0;
      notifyListeners();

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDir.path, 'tafsir'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      if (onProgress != null) onProgress(0.1);
      _downloadProgress = 0.1;
      notifyListeners();

      final response = await client
          .get(Uri.parse(tafsirUrl))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      if (bytes.length < 5000) {
        final check = utf8.decode(bytes, allowMalformed: true);
        if (check.contains('<!DOCTYPE')) {
          throw Exception('Invalid file format received (HTML instead of CSV)');
        }
      }

      // Write to temp file first to verify parsing before replacing production file
      tempFile = File(p.join(targetDir.path, '$fileName.tmp'));
      await tempFile.writeAsBytes(bytes);

      if (onProgress != null) onProgress(0.7);
      _downloadProgress = 0.7;
      notifyListeners();

      // Verify and parse the downloaded content in isolate
      final result = await compute(_parseCsvIsolate, bytes);
      final parsedData = (result != null && result.containsKey('data'))
          ? result['data'] as Map<String, String>?
          : null;

      if (parsedData == null || parsedData.isEmpty) {
        final errorMsg =
            result?['error']?.toString() ??
            'فشل استخراج بيانات التفسير من الملف الذي تم تنزيله';
        throw Exception(errorMsg);
      }

      // Atomic swap: replace production file with verified temp file
      final outFile = File(p.join(targetDir.path, fileName));
      await tempFile.rename(outFile.path);

      _generation++;
      // Update memory state
      _tafsirMap.clear();
      _tafsirMap.addAll(parsedData);
      _isLoaded = true;
      _lastError = null;

      if (onProgress != null) onProgress(1.0);
      _downloadProgress = 1.0;
      _isDownloading = false;
      notifyListeners();
    } catch (e) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      _isDownloading = false;
      _downloadProgress = 0.0;
      _lastError = e.toString();
      notifyListeners();
      debugPrint('LocalTafsirService Download Error: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> loadTafsirData() async {
    if (kIsWeb) return;
    if (_isLoaded && _tafsirMap.isNotEmpty) return;
    if (_loadFuture != null) return _loadFuture;

    _loadFuture = _loadInternal();
    try {
      await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  Future<void> _loadInternal() async {
    final generation = _generation;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDir.path, 'tafsir', fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return;
      }

      final result = await compute(_parseCsvIsolate, bytes);

      if (generation != _generation) return;
      if (result != null && result.containsKey('data')) {
        final data = result['data'] as Map<String, String>;
        if (data.isNotEmpty) {
          _tafsirMap.clear();
          _tafsirMap.addAll(data);
          _isLoaded = true;
          _lastError = null;
          debugPrint(
            'LocalTafsirService: Successfully loaded ${_tafsirMap.length} entries',
          );
        } else {
          _isLoaded = false;
          _lastError =
              result['error']?.toString() ?? 'فشل استخراج البيانات من الملف';
        }
      } else {
        _isLoaded = false;
        _lastError = result?['error']?.toString() ?? 'تعذر تحليل محتوى الملف';
      }
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
      _isLoaded = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<String?> getTafsir(int sura, int aya) async {
    if (!_isLoaded) await loadTafsirData();
    return _tafsirMap['${sura}_$aya'];
  }
}

/// Isolate Parsing Logic (Regex CSV Parser)
Map<String, dynamic>? _parseCsvIsolate(Uint8List bytes) {
  try {
    String content = '';
    try {
      if (bytes.length > 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        content = utf8.decode(bytes.sublist(3));
      } else {
        content = utf8.decode(bytes, allowMalformed: true);
      }
    } catch (_) {
      content = utf8.decode(bytes, allowMalformed: true);
    }

    if (content.isEmpty) return {'error': 'محتوى الملف فارغ'};

    final Map<String, String> map = {};

    // Split by new line
    final lines = content.split('\n');
    if (lines.length < 2) {
      return {'error': 'لم يتم العثور على أسطر (Table Rows)'};
    }

    int skipCount = 0;

    // Regex matches comma separated values taking quotes into account
    final regex = RegExp(r',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = line.split(regex);

      // We expect at least 12 columns
      if (cols.length >= 12) {
        try {
          String sRaw = cols[3].replaceAll('"', '').trim();
          String aRaw = cols[8].replaceAll('"', '').trim();
          String tRaw = cols[11].replaceAll('"', '').trim();

          final int s = int.tryParse(sRaw) ?? 0;
          final int a = int.tryParse(aRaw) ?? 0;

          if (s > 0 && a > 0 && tRaw.isNotEmpty) {
            // Strip HTML tags if any CSV texts contained them
            String cleanTafsir = tRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
            map['${s}_$a'] = cleanTafsir;
          } else {
            skipCount++;
          }
        } catch (_) {
          skipCount++;
        }
      } else {
        skipCount++;
      }
    }

    if (map.isEmpty) {
      return {
        'error':
            'فشل استخراج أي آيات. تأكد من جودة ملف CSV. تم تجاوز $skipCount صف.',
      };
    }

    return {'data': map};
  } catch (e) {
    return {'error': 'حدث خطأ غير متوقع أثناء المعالجة: $e'};
  }
}
