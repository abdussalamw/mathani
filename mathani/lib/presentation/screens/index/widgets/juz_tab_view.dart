import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/data/models/juz_data.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';

/// تبويب الأجزاء مع كعكة دائرية للأحزاب
class JuzTabView extends StatefulWidget {
  const JuzTabView({Key? key}) : super(key: key);

  @override
  State<JuzTabView> createState() => _JuzTabViewState();
}

class _JuzTabViewState extends State<JuzTabView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JuzData> _getFilteredJuz() {
    if (_searchQuery.isEmpty) {
      return juzList;
    }

    return juzList.where((juz) {
      final query = _searchQuery.toLowerCase();
      return juz.number.toString().contains(query) ||
             juz.surahName.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredJuz = _getFilteredJuz();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(fontFamily: 'Tajawal'),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الجزء...',
              hintStyle: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2416) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Juz List
        Expanded(
          child: filteredJuz.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج للبحث',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filteredJuz.length,
                  itemBuilder: (context, index) {
                    final juz = filteredJuz[index];
                    return _buildJuzTile(context, juz, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJuzTile(BuildContext context, JuzData juz, bool isDark) {
    // اسم الجزء بخط QCF4_BSML
    final int juzCodePoint = 0xF1D8 + (juz.number - 1);
    final String juzGlyph = String.fromCharCode(juzCodePoint);

    return InkWell(
      onTap: () {
        // الانتقال للصفحة الأولى من الجزء
        context.read<UiProvider>().jumpToPage(juz.pageNumber);
      },
      child: Container(
        height: 60, // تصغير من 100px
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2416) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // كعكة الأحزاب (Circular Progress)
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 8 أقسام (4 أحزاب × 2 نصف)
                  CustomPaint(
                    size: const Size(44, 44),
                    painter: HizbCirclePainter(
                      segments: 8,
                      isDark: isDark,
                    ),
                  ),
                  // رقم الجزء
                  Text(
                    '${juz.number}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // اسم الجزء (QCF4_BSML) - على اليسار
            Text(
              juzGlyph,
              style: const TextStyle(
                fontFamily: 'QCF4_BSML',
                fontSize: 20,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // معلومات البداية - على اليمين
            Expanded(
              child: Text(
                'من سورة ${juz.surahName} آية ${juz.ayahNumber}',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),
            
            const SizedBox(width: 8),

            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// رسام مخصص للكعكة الدائرية (8 أقسام للأحزاب)
class HizbCirclePainter extends CustomPainter {
  final int segments;
  final bool isDark;

  HizbCirclePainter({
    required this.segments,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / segments;

    for (int i = 0; i < segments; i++) {
      // ألوان متدرجة من الذهبي إلى البرتقالي
      final color = Color.lerp(
        AppColors.golden,
        AppColors.primary.withValues(alpha: 0.7),
        i / segments,
      )!;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      final startAngle = (i * sweepAngle) - (pi / 2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        startAngle,
        sweepAngle - 0.1, // فجوة صغيرة بين الأقسام
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
