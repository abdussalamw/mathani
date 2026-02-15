import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class MushafDownloaderService {
  
  static Future<void> downloadAndExtract({
    required String url,
    required String destinationPath,
    required Function(double progress) onProgress,
  }) async {
    try {
      // 1. Prepare destination
      final destDir = Directory(destinationPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // 2. Download
      final httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
         throw Exception('Failed to download: ${response.statusCode}');
      }
      
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> allBytes = [];
      
      await for (final chunk in response.stream) {
        allBytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          // Download is 0% to 70% of the progress
          onProgress((receivedBytes / totalBytes) * 0.7);
        }
      }
      httpClient.close();
      
      // 3. Extract
      // Extraction is 70% to 100% of the progress
      onProgress(0.75);
      
      if (kIsWeb) {
        // Web extraction not fully supported for persistent storage in this context yet
        // but we can implement logical support if needed.
        return;
      }
      
      // Run extraction in isolate to avoid UI freeze
      await compute(_extractZip, {
        'bytes': allBytes, 
        'path': destinationPath
      });
      
      onProgress(1.0);
      
    } catch (e) {
      debugPrint('Mushaf Download Error: $e');
      throw e;
    }
  }

  static Future<void> _extractZip(Map<String, dynamic> args) async {
    final bytes = args['bytes'] as List<int>;
    final targetPath = args['path'] as String;
    
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        
        // Handle potential nested folders in ZIP: flatten or preserve?
        // For Mushaf images, we usually want them in the root of targetPath 
        // to match ImagePageLoader expectations (001.webp).
        // Check if filename has digits
        final nameParts = filename.split('/');
        final actualName = nameParts.last;
        
        if (actualName.isNotEmpty && !actualName.startsWith('.')) {
             final outFile = File('$targetPath/$actualName');
             outFile.parent.createSync(recursive: true);
             outFile.writeAsBytesSync(data);
        }
      }
    }
  }
}
