import 'package:flutter/material.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SurahHeader extends StatelessWidget {
  final Surah surah;
  
  const SurahHeader({
    Key? key,
    required this.surah,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.golden05,
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // اسم السورة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.golden, width: 2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              'سورة ${surah.nameArabic}',
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // معلومات السورة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.greyDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.golden,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${surah.numberOfAyahs} آية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.greyDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // البسملة (إلا التوبة - رقم 9)
          // ملاحظة: الفاتحة (1) عادة تعرض البسملة كآية رقم 1، ولكن للتنسيق هنا سنعرضها كترويسة إذا لم تكن مكررة
          if (surah.number != 9) ...[
            const SizedBox(height: 24),
            _buildBasmala(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBasmala() {
    return Text(
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      style: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 24,
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        height: 1.8,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
