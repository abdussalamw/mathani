import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'qpc_v1_data_service.dart';
import '../models/page_glyph.dart';

class QPCV1LayoutService {
  static final QPCV1LayoutService _instance = QPCV1LayoutService._internal();
  factory QPCV1LayoutService() => _instance;
  QPCV1LayoutService._internal();

  static const List<String> _surahNames = [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
    "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
    "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
    "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
    "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
    "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
    "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
    "التكوير", "الإنفطار", "المطففين", "الإنشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
    "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
    "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
    "المسد", "الإخلاص", "الفلق", "الناس"
  ];

  Map<int, List<dynamic>>? _rawLayout;
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> _load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final jsonString = await rootBundle.loadString('assets/data/qpc_v1_layout.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      
      _rawLayout = {};
      for (int p = 1; p <= 604; p++) {
        final pageKey = p.toString();
        if (decoded.containsKey(pageKey)) {
          _rawLayout![p] = decoded[pageKey];
        }
      }
      debugPrint('Successfully loaded QPC V1 Layout');
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading QPC V1 Layout: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<List<PageLine>> getLinesForPage(int page) async {
    if (!_isLoaded) await _load();
    if (_rawLayout == null || !_rawLayout!.containsKey(page)) return [];

    final dataService = QPCV1DataService();
    if (!dataService.isLoaded) await dataService.load();

    final List<dynamic> rawLines = _rawLayout![page]!;
    final List<PageLine> lines = [];

    for (int i = 0; i < rawLines.length; i++) {
      final List<dynamic> rawGlyphs = rawLines[i];
      final List<Glyph> lineGlyphs = [];

      for (var raw in rawGlyphs) {
        final int type = raw['t'] ?? 0;
        final int? s = raw['s'];
        final int? a = raw['a'];
        final int? w = raw['w']; // Word ID from layout JSON (null for non-word types)
        
        String code = '';

        if (type == 1) {
          // === Type 1: Word ===
          // Use the word ID directly from the layout JSON for precise PUA lookup
          if (s != null && a != null && w != null) {
            code = dataService.getGlyph(s, a, w) ?? '';
          }
        } else if (type == 2) {
          // === Type 2: Ayah End ===
          // New layout has w (word index) directly for ayah ends
          if (s != null && a != null && w != null) {
            code = dataService.getGlyph(s, a, w) ?? '';
          }
          // Fallback if no PUA glyph found
          if (code.isEmpty) {
            code = String.fromCharCode(0x06DD);
          }
        } else if (type == 3 || type == 4 || type == 5) {
          // === Type 3: Pause Mark, Type 4: Sajdah, Type 5: Other ===
          // These have w=null and no entries in qpc_v1_glyphs.json
          // Leave code empty - they will be rendered as invisible or with a fallback
          code = '';
        } else if (type == 6) {
          // === Type 6: Surah Header ===
          if (s != null && s >= 1 && s <= 114) {
            code = String.fromCharCode(0xF100 + (s - 1));
          }
        } else if (type == 8) {
          // === Type 8: Basmala ===
          code = 'BSML';
        }

        lineGlyphs.add(Glyph(
          type: type,
          surah: s,
          ayah: a,
          wordId: w,
          code: code,
        ));
      }

      lines.add(PageLine(
        line: i + 1,
        glyphs: lineGlyphs,
      ));
    }

    return lines;
  }
}
