import '../../core/utils/async_work_pool.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Service to provide official line alignment data (is_centered) for QPC V1 Mushaf.
/// Data sourced from QUL's QPC V1 layout database (1405H print).
class QPCV1AlignmentService {
  static final QPCV1AlignmentService _instance =
      QPCV1AlignmentService._internal();
  factory QPCV1AlignmentService() => _instance;
  QPCV1AlignmentService._internal();

  Map<String, dynamic>? _data;
  bool _isLoaded = false;
  int _generation = 0;

  void invalidate() {
    _generation++;
    _data = null;
    _isLoaded = false;
  }

  final _loadWork = AsyncWorkPool<int, void>();

  Future<void> load() =>
      _loadWork.run(_generation, () => _loadOnce(_generation));

  Future<void> _loadOnce(int generation) async {
    if (_isLoaded && _data != null && _data!.isNotEmpty) return;

    try {
      String jsonString;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File(
          '${appDir.path}/mushafs/madani_old_v1/qpc_v1_line_alignment.json',
        );
        if (await localFile.exists()) {
          jsonString = await localFile.readAsString();
        } else {
          try {
            jsonString = await rootBundle.loadString(
              'assets/data/qpc_v1_line_alignment.json',
            );
          } catch (_) {
            jsonString = '{}';
          }
        }
      } else {
        try {
          jsonString = await rootBundle.loadString(
            'assets/data/qpc_v1_line_alignment.json',
          );
        } catch (_) {
          jsonString = '{}';
        }
      }
      if (generation != _generation) return;
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      if (parsed.isNotEmpty) {
        _data = parsed;
        _isLoaded = true;
        debugPrint('QPC V1 Alignment data loaded: ${_data!.length} pages');
      } else {
        _isLoaded = false;
      }
    } catch (e) {
      if (generation != _generation) return;
      debugPrint('Error loading QPC V1 alignment data: $e');
      _isLoaded = false;
    }
  }

  bool isCentered(int page, int line) {
    if (!_isLoaded || _data == null) return false;
    final pageData = _data![page.toString()];
    if (pageData == null) return false;
    final lineData = pageData[line.toString()];
    if (lineData == null) return false;
    return lineData['c'] == 1;
  }

  bool get isLoaded => _isLoaded;
}
