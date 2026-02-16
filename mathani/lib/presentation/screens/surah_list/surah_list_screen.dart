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
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                mainAxisExtent: 60, // Fixed height per item
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildSurahTile(context, filteredSurahs[index], isDark),
                                childCount: filteredSurahs.length,
                              ),
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
    final surah = surahs.firstWhere(
      (s) => s.number == ayah.surahNumber,
      orElse: () => Surah()
        ..number = 0
        ..nameArabic = '?'
        ..nameEnglish = '?'
        ..numberOfAyahs = 0
        ..revelationType = 'Meccan',
    );

    return InkWell(
      onTap: () {
        final page = ayah.page;
        if (page > 0) {
          context.read<UiProvider>().jumpToPage(page);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2416) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.brown.withValues(alpha: 0.3) : Colors.brown.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${surah.nameArabic} • صفحة ${ayah.page}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                Icon(Icons.chevron_left_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getContextualText(ayah.text, _searchQuery),
              style: TextStyle(
                fontFamily: 'UthmanicHafs_V22',
                fontSize: 16,
                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  String _getContextualText(String text, String query) {
    if (query.isEmpty) return text;
    
    final normalizedText = TextUtils.normalizeQuranText(text);
    final normalizedQuery = TextUtils.normalizeQuranText(query);
    
    final index = normalizedText.indexOf(normalizedQuery);
    if (index == -1) return text;
    
    // Simple word-based context
    final words = text.split(' ');
    // We can't easily map back from normalized index to actual word index perfectly without complex logic
    // but we can try to find the word that contains the first character of the match
    
    // For now, let's keep it simple: show the text around the match area
    int start = (index - 30).clamp(0, text.length);
    int end = (index + query.length + 30).clamp(0, text.length);
    
    String result = text.substring(start, end);
    if (start > 0) result = '...$result';
    if (end < text.length) result = '$result...';
    
    return result;
  }

  Widget _buildSurahTile(BuildContext context, Surah surah, bool isDark) {
    return InkWell(
      onTap: () {
        final navProvider = context.read<MushafNavigationProvider>();
        context.read<UiProvider>().jumpToSurah(surah.number, navProvider);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2416) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.golden.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Number Circle
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.golden, width: 1.5),
              ),
              child: Text(
                '${surah.number}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Name
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    String.fromCharCode(0xF100 + (surah.number - 1)), // Use QCF4 Glyph
                    style: const TextStyle(
                      fontFamily: 'QCF4_BSML',
                      fontSize: 11, // Reduced by ~400% (from 40) to match Top Bar
                      color: AppColors.primary,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible, 
                  ),
                  Text(
                    '${surah.numberOfAyahs} آية',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
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
