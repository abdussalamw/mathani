import 'package:material_ui/material_ui.dart';
import 'package:mathani/l10n/app_localizations.dart';

import 'dart:async';

import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/core/utils/text_utils.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart'; // Added
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController =
      TextEditingController(); // Controller for better management

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranProvider>().loadSurahs();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Debouncer
  Timer? _debounce;

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<QuranProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchSurahHint,
                hintStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppColors.mutedText,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.brandGold,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
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
                fillColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.surahs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandGold,
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.surahs.isEmpty) {
                  return Center(child: Text(provider.errorMessage!));
                }

                final filteredSurahs = _getFilteredSurahs(provider.surahs);
                final ayahResults = provider.searchResults;

                if (filteredSurahs.isEmpty &&
                    ayahResults.isEmpty &&
                    _searchQuery.isNotEmpty) {
                  if (provider.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandGold,
                      ),
                    );
                  }
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noResults,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.mutedText,
                      ),
                    ),
                  );
                }

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (filteredSurahs.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandGold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.surahsSection,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.slateText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildSurahTile(
                                  context,
                                  filteredSurahs[index],
                                  isDark,
                                ),
                              ),
                              childCount: filteredSurahs.length,
                            ),
                          ),
                        ),
                      ],

                      if (provider.isSearching)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.brandGold,
                              ),
                            ),
                          ),
                        ),

                      if (!provider.isSearching && ayahResults.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandGold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.ayahsSection,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.slateText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildAyahTile(
                              context,
                              ayahResults[index],
                              isDark,
                              provider.surahs,
                            ),
                            childCount: ayahResults.length,
                          ),
                        ),
                      ],

                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 120),
                      ),
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

  Widget _buildAyahTile(
    BuildContext context,
    Ayah ayah,
    bool isDark,
    List<Surah> surahs,
  ) {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${surah.nameArabic} • آية ${ayah.ayahNumber} • صفحة ${ayah.page}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppColors.brandGold,
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 10,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildHighlightedText(ayah.text, _searchQuery, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, bool isDark) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13.5,
          color: isDark ? const Color(0xFFE0E0E0) : AppColors.slateText,
          height: 1.4,
        ),
      );
    }

    final contextualText = _getContextualText(text, query);
    final normalizedContext = TextUtils.normalizeQuranText(contextualText);
    final normalizedQuery = TextUtils.normalizeQuranText(query);

    final List<TextSpan> spans = [];
    final int index = normalizedContext.indexOf(normalizedQuery);

    if (index != -1) {
      // Before match
      if (index > 0) {
        spans.add(TextSpan(text: contextualText.substring(0, index)));
      }
      // Match
      spans.add(
        TextSpan(
          text: contextualText.substring(index, index + query.length),
          style: const TextStyle(
            color: AppColors.brandGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      // After match
      if (index + query.length < contextualText.length) {
        spans.add(
          TextSpan(text: contextualText.substring(index + query.length)),
        );
      }
    } else {
      spans.add(TextSpan(text: contextualText));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13.5,
          color: isDark ? const Color(0xFFE0E0E0) : AppColors.slateText,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  String _getContextualText(String text, String query) {
    if (query.isEmpty) return text;

    final normalizedText = TextUtils.normalizeQuranText(text);
    final normalizedQuery = TextUtils.normalizeQuranText(query);

    final index = normalizedText.indexOf(normalizedQuery);
    if (index == -1) return text;

    int start = (index - 30).clamp(0, text.length);
    int end = (index + query.length + 30).clamp(0, text.length);

    String result = text.substring(start, end);
    if (start > 0) result = '...$result';
    if (end < text.length) result = '$result...';

    return result;
  }

  Widget _buildSurahTile(BuildContext context, Surah surah, bool isDark) {
    return InkWell(
      key: ValueKey('surah-index-${surah.number}'),
      onTap: () {
        final navProvider = context.read<MushafNavigationProvider>();
        context.read<UiProvider>().jumpToSurah(surah.number, navProvider);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            // Number Badge
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${surah.number}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGold,
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
                  // Surah Name Glyph (QCF4_BSML)
                  Text(
                    String.fromCharCode(0xF100 + (surah.number - 1)),
                    semanticsLabel: surah.nameArabic,
                    style: const TextStyle(
                      fontFamily: 'QCF4_BSML',
                      fontSize: 22, // Calligraphic font needs to be larger to be readable
                      color: AppColors.slateText,
                      height: 1.0,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.numberOfAyahs} آية',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9,
                      color: AppColors.mutedText,
                    ),
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
          surah.nameEnglish.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          surah.number.toString() == _searchQuery;
    }).toList();
  }
}
