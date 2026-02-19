import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to provide official line alignment data (is_centered) for QPC V1 Mushaf.
/// Data sourced from QUL's QPC V1 layout database (1405H print).
class QPCV1AlignmentService {
  static final QPCV1AlignmentService _instance = QPCV1AlignmentService._internal();
  factory QPCV1AlignmentService() => _instance;
  QPCV1AlignmentService._internal();

  Map<String, dynamic>? _data;
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final jsonString = await rootBundle.loadString('assets/data/qpc_v1_line_alignment.json');
      _data = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('QPC V1 Alignment data loaded: ${_data!.length} pages');
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading QPC V1 alignment data: $e');
    } finally {
      _isLoading = false;
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
