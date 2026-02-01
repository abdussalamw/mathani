import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'العلامات المرجعية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          final bookmarks = bookmarkProvider.bookmarks;

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
                  uiProvider.jumpToSurah(bookmark.surahNumber);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جاري الانتقال لآية ${bookmark.ayahNumber}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2416) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.golden.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: AppColors.golden),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سورة ${bookmark.surahNumber} - آية ${bookmark.ayahNumber}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateString,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
