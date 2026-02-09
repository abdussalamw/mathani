import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/screens/mushaf/mushaf_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({Key? key}) : super(key: key);

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController(); // Controller for better management

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurahs();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'ابحث باسم السورة أو رقمها...',
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
          
          // Surah List
          Expanded(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          style: const TextStyle(fontFamily: 'Tajawal'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadSurahs(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.surahs.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات', style: TextStyle(fontFamily: 'Tajawal')));
                }

                final filteredSurahs = _getFilteredSurahs(provider.surahs);

                if (filteredSurahs.isEmpty) {
                  return Center(
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
                  );
                }

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100), // Increased padding for BottomBar
                    itemCount: filteredSurahs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final surah = filteredSurahs[index];
                      return _buildSurahTile(context, surah, isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah, bool isDark) {
    // رقم السورة → Unicode للخط QCF4_BSML
    final int surahCodePoint = 0xF100 + (surah.number - 1);
    final String surahGlyph = String.fromCharCode(surahCodePoint);
    
    return InkWell(
      onTap: () {
        context.read<UiProvider>().jumpToSurah(surah.number);
      },
      child: Container(
        height: 60, // تصغير من 80px
        color: isDark ? const Color(0xFF231E18) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Number container
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Removed risky AssetImage
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.golden.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isDark ? const Color(0xFF2C2416) : Colors.grey[100],
              ),
              child: Text(
                '${surah.number}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Name (QCF4_BSML) - على اليسار
            Text(
              surahGlyph,
              style: const TextStyle(
                fontFamily: 'QCF4_BSML',
                fontSize: 22,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Info - على اليمين
            Expanded(
              child: Text(
                '${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'} • ${surah.numberOfAyahs} آية',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Arrow
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), ''); // Remove Tashkeel
  }

  List<Surah> _getFilteredSurahs(List<Surah> surahs) {
    if (_searchQuery.isEmpty) return surahs;
    
    final normalizedQuery = _normalizeArabic(_searchQuery);
    
    return surahs.where((surah) {
      final normalizedName = _normalizeArabic(surah.nameArabic);
      return normalizedName.contains(normalizedQuery) ||
             surah.nameEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             surah.number.toString() == _searchQuery;
    }).toList();
  }
}
