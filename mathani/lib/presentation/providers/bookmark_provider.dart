import 'package:flutter/material.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:isar/isar.dart';

class BookmarkProvider extends ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final isar = IsarService.instance.isar;
    _bookmarks = await isar.collection<Bookmark>().where().findAll();
    notifyListeners();
  }

  Future<void> addBookmark(int surah, int ayah, {String? note}) async {
    final isar = IsarService.instance.isar;
    final bookmark = Bookmark()
      ..surahNumber = surah
      ..ayahNumber = ayah
      ..createdAt = DateTime.now()
      ..note = note;

    await isar.writeTxn(() async {
      await isar.collection<Bookmark>().put(bookmark);
    });
    
    await _loadBookmarks();
  }

  Future<void> removeBookmark(int surah, int ayah) async {
    final isar = IsarService.instance.isar;
    await isar.writeTxn(() async {
      await isar.collection<Bookmark>()
          .filter()
          .surahNumberEqualTo(surah)
          .ayahNumberEqualTo(ayah)
          .deleteAll();
    });
    
    await _loadBookmarks();
  }

  bool isBookmarked(int surah, int ayah) {
    return _bookmarks.any((b) => b.surahNumber == surah && b.ayahNumber == ayah);
  }

  // --- Page Bookmark Logic (Surah = 0, Ayah = PageNumber) ---
  
  Future<void> addPageBookmark(int pageNumber) async {
    // Check if already exists to avoid duplicates
    if (isPageBookmarked(pageNumber)) return;
    
    await addBookmark(0, pageNumber, note: 'Page $pageNumber');
  }

  Future<void> removePageBookmark(int pageNumber) async {
    await removeBookmark(0, pageNumber);
  }

  bool isPageBookmarked(int pageNumber) {
    return _bookmarks.any((b) => b.surahNumber == 0 && b.ayahNumber == pageNumber);
  }
  
  void togglePageBookmark(int pageNumber) {
    if (isPageBookmarked(pageNumber)) {
      removePageBookmark(pageNumber);
    } else {
      addPageBookmark(pageNumber);
    }
  }
}
