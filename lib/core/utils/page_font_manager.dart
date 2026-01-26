
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class PageFontManager {
  static final PageFontManager _instance = PageFontManager._privateConstructor();
  static PageFontManager get instance => _instance;
  
  PageFontManager._privateConstructor();

  final Set<int> _loadedPages = {};

  Future<void> loadPageFont(int pageNumber, String localPath) async {
    if (_loadedPages.contains(pageNumber)) return;

    final fontName = 'qcf_page_$pageNumber';
    final fontFile = File('$localPath/p${pageNumber.toString().padLeft(3, '0')}.woff2');

    if (!await fontFile.exists()) {
       debugPrint('Font file not found: ${fontFile.path}');
       return;
    }

    try {
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontFile.readAsBytesSync().buffer)));
      await fontLoader.load();
      _loadedPages.add(pageNumber);
      // debugPrint('Loaded font: $fontName');
    } catch (e) {
      debugPrint('Error loading font for page $pageNumber: $e');
    }
  }
  
  String getFontName(int pageNumber) => 'qcf_page_$pageNumber';

  void unloadPageFont(int pageNumber) {
    // Flutter FontLoader doesn't strictly support 'unloading' easily in stable yet,
    // but usually LRU naming strategies or relying on OS cache is done.
    // For now we just track what we 'attempted' to load.
    // Ideally we would unregister, but FontLoader is add-only for now. 
    // We will minimize memory usage by ensuring files are woff2 (compressed).
  }
}
