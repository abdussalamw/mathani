import 'package:flutter/material.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// الحصول على رمز اسم السورة من خط QCF4_BSML
  String _getSurahGlyph(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return '';
    final codePoint = 0xF100 + (surahNumber - 1);
    return String.fromCharCode(codePoint);
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
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchBookmarks,
                hintStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppColors.mutedText,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.brandGold, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
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
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          
          // Bookmarks List
          Expanded(
            child: Consumer2<BookmarkProvider, QuranProvider>(
              builder: (context, bookmarkProvider, quranProvider, child) {
                final allBookmarks = bookmarkProvider.bookmarks;
                
                // Filter bookmarks based on search query
                final bookmarks = _searchQuery.isEmpty
                    ? allBookmarks
                    : allBookmarks.where((bookmark) {
                        final surah = quranProvider.surahs.firstWhere(
                          (s) => s.number == bookmark.surahNumber,
                          orElse: () => quranProvider.surahs.first,
                        );
                        return bookmark.surahNumber.toString().contains(_searchQuery) ||
                               bookmark.ayahNumber.toString().contains(_searchQuery) ||
                               surah.nameArabic.contains(_searchQuery);
                      }).toList();

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noBookmarksYet,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.bookmarkHint,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              final dateString = DateFormat('yyyy/MM/dd - hh:mm a').format(bookmark.createdAt);
              
              // الحصول على معلومات السورة
              final surah = quranProvider.surahs.firstWhere(
                (s) => s.number == bookmark.surahNumber,
                orElse: () => quranProvider.surahs.isNotEmpty 
                    ? quranProvider.surahs.first 
                    : Surah()..number = bookmark.surahNumber,
              );
              
              return Dismissible(
                key: Key('bookmark_${bookmark.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  bookmarkProvider.removeBookmark(bookmark.surahNumber, bookmark.ayahNumber);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.bookmarkDeleted)),
                  );
                },
                child: InkWell(
                  onTap: () {
                    final uiProvider = Provider.of<UiProvider>(context, listen: false);
                    final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
                    uiProvider.jumpToSurah(bookmark.surahNumber, navProvider);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.goingToAyah(bookmark.ayahNumber)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        // Icon Badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: AppColors.brandGold, size: 16),
                        ),
                        const SizedBox(width: 12),
                        
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                surah.nameArabic,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slateText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppLocalizations.of(context)!.ayahNum(bookmark.ayahNumber)} • صفحة ${surah.page ?? ""}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Date or Arrow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MM/dd').format(bookmark.createdAt),
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppColors.mutedText),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
          },
        ),
      ),
        ],
      ),
    );
  }
}
