import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImagePageLoader {
  static Future<String> getLocalPath(String mushafId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final path = '${appDir.path}/mushafs/$mushafId';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  static Future<File?> getPageImage(
    String mushafId, 
    int pageNumber, 
    String baseUrl, 
    {String extension = 'jpg'}
  ) async {
    try {
      final localDir = await getLocalPath(mushafId);
      final padPage = pageNumber.toString().padLeft(3, '0');
      
      // 1. Check ALL possible local extensions first
      // This ensures if we switched metadata from webp -> png, but files are still webp, we load them.
      // Also checking for 'page_' prefix based on user feedback.
      final supportedExtensions = ['webp', 'png', 'jpg'];
      for (var ext in supportedExtensions) {
         // Pattern A: 001.png
         final f1 = File('$localDir/$padPage.$ext');
         if (await f1.exists()) return f1;
         
         // Pattern B: 1.png
         final f2 = File('$localDir/$pageNumber.$ext');
         if (await f2.exists()) return f2;

         // Pattern C: page_001.png (User reported format)
         final f3 = File('$localDir/page_$padPage.$ext');
         if (await f3.exists()) return f3;
      }


      
      // 2. Download if not exists
      // Prioritize the requested extension for download
      String baseUrlFormatted = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      
      final extensionsToTry = [extension];
      for (var ext in ['webp', 'png', 'jpg']) {
         if (!extensionsToTry.contains(ext)) extensionsToTry.add(ext);
      }
      
      for (var ext in extensionsToTry) {
        // Try padded first (e.g. 001.webp)
        String paddedUrl = '${baseUrlFormatted}$padPage.$ext';
        if (kDebugMode) print('Trying: $paddedUrl');
        
        var response = await http.get(Uri.parse(paddedUrl));
        
        if (response.statusCode == 200) {
           // Success! Save with correct extension
           final correctFile = File('$localDir/$padPage.$ext');
           await correctFile.writeAsBytes(response.bodyBytes);
           return correctFile;
        }
        
        // If padded fails, try unpadded (e.g. 1.webp)
        String unpaddedUrl = '${baseUrlFormatted}$pageNumber.$ext';
        if (kDebugMode) print('Trying Unpadded: $unpaddedUrl');
        
        response = await http.get(Uri.parse(unpaddedUrl));
        
        if (response.statusCode == 200) {
           // Success! Save as padded locally for consistency
           final correctFile = File('$localDir/$padPage.$ext');
           await correctFile.writeAsBytes(response.bodyBytes);
           return correctFile;
        }
      }
      
      debugPrint('Failed to download image with any extension');
      return null;
    } catch (e) {
      debugPrint('Error getting page image: $e');
      return null;
    }
  }
  
  static Future<bool> isPageCached(String mushafId, int pageNumber, {String extension = 'jpg'}) async {
    final localDir = await getLocalPath(mushafId);
    final padPage = pageNumber.toString().padLeft(3, '0');
    final file = File('$localDir/$padPage.$extension');
    return file.exists();
  }
}
