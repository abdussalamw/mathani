import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/core/utils/text_utils.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart'; // Added
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
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



  // Debouncer
  Timer? _debounce;

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
       context.read<QuranProvider>().search(query);
    });
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
              onChanged: _onSearchChanged,
              style: const TextStyle(fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'ابحث باسم السورة أو بآية...',
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
                         context.read<QuranProvider>().clearSearch();
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
          
          // Results
          Expanded(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.surahs.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (provider.errorMessage != null && provider.surahs.isEmpty) {
                   return Center(child: Text(provider.errorMessage!));
                }
                
                final filteredSurahs = _getFilteredSurahs(provider.surahs);
                final ayahResults = provider.searchResults;
                
                // If searching show loading for search only if strict needs? 
                // Actually provider.isSearching is available but maybe we don't want to block UI.

                if (filteredSurahs.isEmpty && ayahResults.isEmpty && _searchQuery.isNotEmpty) {
                   if (provider.isSearching) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                   }
                   return Center(child: Text('لا توجد نتائج', style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.grey : Colors.grey[600])));
                }

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: CustomScrollView(
                    slivers: [
                       if (filteredSurahs.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('السور', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildSurahTile(context, filteredSurahs[index], isDark),
                              childCount: filteredSurahs.length,
                            ),
                          ),
                       ],
                       
                       if (provider.isSearching)
                          const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),

                       if (!provider.isSearching && ayahResults.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('الآيات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildAyahTile(context, ayahResults[index], isDark, provider.surahs),
                              childCount: ayahResults.length,
                            ),
                          ),
                       ],
                       
                       const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahTile(BuildContext context, Ayah ayah, bool isDark, List<Surah> surahs) {
     final surah = surahs.firstWhere((s) => s.number == ayah.surahNumber, orElse: () => Surah()..number = 0..nameArabic = '?'..nameEnglish = '?'..numberOfAyahs = 0..revelationType = 'Meccan');
     
     return InkWell(
        onTap: () {
           final page = ayah.page; 
           if (page > 0) {
              context.read<UiProvider>().jumpToPage(page);
           }
        },
        child: Container(
           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: isDark ? const Color(0xFF2C2416) : Colors.white,
             borderRadius: BorderRadius.circular(12),
             boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
             ],
             border: Border.all(color: isDark ? Colors.brown.withOpacity(0.3) : Colors.brown.withOpacity(0.1)),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                       color: AppColors.primary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       '${surah.nameArabic} : ${ayah.ayahNumber}', 
                       style: const TextStyle(
                         fontFamily: 'Tajawal', 
                         fontWeight: FontWeight.bold,
                         fontSize: 12, 
                         color: AppColors.primary
                       ),
                     ),
                   ),
                   Text(
                     'صفحة ${ayah.page}', 
                     style: TextStyle(
                       fontFamily: 'Tajawal', 
                       fontSize: 12, 
                       color: isDark ? Colors.grey[400] : Colors.grey[600]
                     )
                   ),
                 ],
               ),
               const SizedBox(height: 12),
               Text(ayah.text, 
                 style: TextStyle(
                   fontFamily: 'UthmanicHafs', 
                   fontSize: 20, // Larger font for Quran
                   height: 1.6,
                   color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121),
                 ),
                 maxLines: 3,
                 overflow: TextOverflow.ellipsis,
                 textAlign: TextAlign.justify,
               ),
             ],
           ),
        ),
     );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah, bool isDark) {
    // رقم السورة → Unicode للخط QCF4_BSML
    final int surahCodePoint = 0xF100 + (surah.number - 1);
    final String surahGlyph = String.fromCharCode(surahCodePoint);
    
    return InkWell(
      onTap: () {
        final navProvider = context.read<MushafNavigationProvider>();
        context.read<UiProvider>().jumpToSurah(surah.number, navProvider);
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
  List<Surah> _getFilteredSurahs(List<Surah> surahs) {
    if (_searchQuery.isEmpty) return surahs;
    
    final normalizedQuery = TextUtils.normalizeQuranText(_searchQuery);
    
    return surahs.where((surah) {
      final normalizedName = TextUtils.normalizeQuranText(surah.nameArabic);
      return normalizedName.contains(normalizedQuery) ||
             surah.nameEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             surah.number.toString() == _searchQuery;
    }).toList();
  }
}
