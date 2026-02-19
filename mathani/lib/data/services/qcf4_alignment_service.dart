import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to provide official line alignment data (is_centered) for QCF4 Mushaf.
/// Data sourced from QUL's KFGQPC V4 layout database.
class QCF4AlignmentService {
  static final QCF4AlignmentService _instance = QCF4AlignmentService._internal();
  factory QCF4AlignmentService() => _instance;
  QCF4AlignmentService._internal();

  Map<String, dynamic>? _data;
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final jsonString = await rootBundle.loadString('assets/data/qcf4_line_alignment.json');
      _data = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('QCF4 Alignment data loaded: ${_data!.length} pages');
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading QCF4 alignment data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Returns true if the line should be centered, false if justified.
  /// Falls back to false (justified) if data not available.
  bool isCentered(int page, int line) {
    if (!_isLoaded || _data == null) return false;
    final pageData = _data![page.toString()];
    if (pageData == null) return false;
    final lineData = pageData[line.toString()];
    if (lineData == null) return false;
    return lineData['c'] == 1;
  }

  /// Returns the line type: 'a' (ayah), 's' (surah_name), 'b' (basmallah)
  String getLineType(int page, int line) {
    if (!_isLoaded || _data == null) return 'a';
    final pageData = _data![page.toString()];
    if (pageData == null) return 'a';
    final lineData = pageData[line.toString()];
    if (lineData == null) return 'a';
    return lineData['t'] ?? 'a';
  }

  bool get isLoaded => _isLoaded;
}
