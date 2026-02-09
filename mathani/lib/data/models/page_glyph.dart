/// نموذج بيانات لصفحة من المصحف
class PageGlyph {
  final int page;
  final List<PageLine> lines;
  
  PageGlyph({
    required this.page,
    required this.lines,
  });
  
  factory PageGlyph.fromJson(Map<String, dynamic> json) {
    return PageGlyph(
      page: json['page'] as int,
      lines: (json['lines'] as List<dynamic>)
          .map((line) => PageLine.fromJson(line as Map<String, dynamic>))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}

/// نموذج بيانات لسطر في الصفحة
class PageLine {
  final int line;
  final List<Glyph> glyphs;
  
  PageLine({
    required this.line,
    required this.glyphs,
  });
  
  factory PageLine.fromJson(Map<String, dynamic> json) {
    return PageLine(
      line: json['line'] as int,
      glyphs: (json['glyphs'] as List<dynamic>)
          .map((glyph) => Glyph.fromJson(glyph as Map<String, dynamic>))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'glyphs': glyphs.map((glyph) => glyph.toJson()).toList(),
    };
  }
}

/// نموذج بيانات لرمز (Glyph) واحد
class Glyph {
  final int? id;
  final String code;
  final int type; // 1=word, 2=ayah_end, 3=pause, 4=sajdah, 6=basmala, 8=surah_name
  final int? order;
  final int? surah;
  final int? ayah;
  final int? wordId;
  
  Glyph({
    this.id,
    required this.code,
    required this.type,
    this.order,
    this.surah,
    this.ayah,
    this.wordId,
  });
  
  factory Glyph.fromJson(Map<String, dynamic> json) {
    return Glyph(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      type: json['type'] as int,
      order: json['order'] as int?,
      surah: json['sura'] as int?, // Note: 'sura' not 'surah' in new JSON
      ayah: json['ayah'] as int?,
      wordId: json['word_id'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'order': order,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (wordId != null) 'word_id': wordId,
    };
  }
  
  /// التحقق من نوع العنصر
  bool get isWord => type == 1;
  bool get isAyahEnd => type == 2;
  bool get isPause => type == 3;
  bool get isSajdah => type == 4;
  bool get isBasmala => type == 8; // Type 8 is Basmala (Empty code logic)
  bool get isSurahName => type == 6; // Type 6 is Surah Name (Has value \uf1xx)
}
