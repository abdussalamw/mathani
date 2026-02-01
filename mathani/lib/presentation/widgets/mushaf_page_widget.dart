import 'package:flutter/material.dart';
import '../../data/models/page_glyph.dart';
import '../../core/constants/app_colors.dart';
import 'page_line_widget.dart';

import '../../data/services/qcf4_font_downloader.dart';

/// Widget لعرض صفحة كاملة من المصحف
class MushafPageWidget extends StatefulWidget {
  final PageGlyph page;
  final int? selectedSurah;
  final int? selectedAyah;
  final Function(int surah, int ayah)? onAyahSelected;
  
  const MushafPageWidget({
    Key? key,
    required this.page,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahSelected,
  }) : super(key: key);

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  bool _isFontLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPageFonts();
  }

  @override
  void didUpdateWidget(MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.page != widget.page.page) {
      _loadPageFonts();
    }
  }

  Future<void> _loadPageFonts() async {
    // Load page font once for all lines
    final loaded = await QCF4FontDownloader.loadPageFont(widget.page.page);
    await QCF4FontDownloader.loadBasmalaFont();
    if (mounted) {
      setState(() {
        _isFontLoaded = loaded;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      // Removed margin and padding to maximize space
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2C2416) 
            : const Color(0xFFFFFBF0),
        // Removed border to feel more immersive
      ),
      child: Column(
        children: [
          // شريط المعلومات العلوي - Ultra Compact
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.page.page}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.brown[700],
                  ),
                ),
                // Try to find Surah name if this page has a Surah header
                Builder(
                  builder: (context) {
                    try {
                      final surahLine = widget.page.lines.firstWhere(
                        (l) => l.glyphs.any((g) => g.isSurahName),
                      );
                      final surahName = surahLine.glyphs.firstWhere((g) => g.isSurahName).code;
                      return Text(
                        'سورة $surahName',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.golden,
                        ),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // الأسطر
          Expanded(
            child: !_isFontLoaded 
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate optimal height utilization
                    return FittedBox(
                      fit: BoxFit.fitWidth, // Force full width to eliminate side margins
                      alignment: Alignment.topCenter, // Align top to kill top margin
                      child: SizedBox(
                        width: 1000, 
                        // No fixed height, let content flow
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread vertical if space exists
                          children: widget.page.lines.map((line) {
                            return PageLineWidget(
                                line: line,
                                pageNumber: widget.page.page,
                                isParentFontLoaded: _isFontLoaded,
                                selectedSurah: widget.selectedSurah,
                                selectedAyah: widget.selectedAyah,
                                onAyahSelected: widget.onAyahSelected,
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
