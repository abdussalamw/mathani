import 'package:flutter/material.dart';
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
      color: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      child: Column(
        children: [
          // مسافة علوية لتجنب تداخل العنوان
          const SizedBox(height: 60),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'ابحث في العلامات...',
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
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد علامات محفوظة بعد',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط مطولاً على الآية في المصحف لحفظها',
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
            padding: const EdgeInsets.all(16),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  bookmarkProvider.removeBookmark(bookmark.surahNumber, bookmark.ayahNumber);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف العلامة')),
                  );
                },
                child: InkWell(
                onTap: () {
                  final uiProvider = Provider.of<UiProvider>(context, listen: false);
                  final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
                  uiProvider.jumpToSurah(bookmark.surahNumber, navProvider);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جاري الانتقال لآية ${bookmark.ayahNumber}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        // أيقونة العلامة
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.golden.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: AppColors.golden, size: 18),
                        ),
                        const SizedBox(width: 12),
                        
                        // اسم السورة على اليمين
                        Expanded(
                          flex: 2,
                          child: Text(
                            _getSurahGlyph(bookmark.surahNumber),
                            style: const TextStyle(
                              fontFamily: 'QCF4_BSML',
                              fontSize: 16, // 50% أصغر من 20
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // التفاصيل على اليسار
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // رقم الآية
                              Text(
                                'آية ${bookmark.ayahNumber}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // الجزء والصفحة
                              if (surah.juzStart != null || surah.page != null)
                                Row(
                                  children: [
                                    if (surah.juzStart != null) ...[
                                      Text(
                                        'ج${surah.juzStart}',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    if (surah.juzStart != null && surah.page != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('•', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                      ),
                                    if (surah.page != null) ...[
                                      Text(
                                        'ص${surah.page}',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
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
