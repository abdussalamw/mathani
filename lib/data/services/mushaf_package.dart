import 'dart:convert';
import 'dart:io';

import 'dart:isolate';
import 'dart:typed_data';

import '../models/page_glyph.dart';

/// Directory.rename cannot replace a populated directory. Keep its previous
/// contents until the new directory has been committed on the same filesystem.
void recoverMushafDirectory(Directory target) {
  final previous = Directory('${target.path}.previous');
  if (!target.existsSync() && previous.existsSync()) {
    previous.renameSync(target.path);
  }
}

void commitMushafDirectory(Directory staged, Directory target) {
  recoverMushafDirectory(target);
  final previous = Directory('${target.path}.previous');
  if (previous.existsSync()) previous.deleteSync(recursive: true);
  if (target.existsSync()) target.renameSync(previous.path);
  try {
    staged.renameSync(target.path);
  } catch (_) {
    recoverMushafDirectory(target);
    rethrow;
  }
  if (previous.existsSync()) {
    try {
      previous.deleteSync(recursive: true);
    } on FileSystemException {
      // The installation is already committed. Retry cleanup on the next update.
    }
  }
}

Future<bool> validMushafPackage(String id, Directory dir) async {
  if (!dir.existsSync()) return false;
  final path = dir.path;
  return Isolate.run(() => _validate((id, path)));
}

bool _validate((String, String) args) {
  final (id, root) = args;
  try {
    final files = {
      for (final f in Directory(root).listSync().whereType<File>())
        f.uri.pathSegments.last: f,
    };
    final images = id == 'shamarly_15lines';
    final qcf = id == 'qcf2_v4_woff2';
    if (!qcf && !images && id != 'madani_old_v1') return false;
    for (var page = 1; page <= (images ? 521 : 604); page++) {
      final n = page.toString().padLeft(3, '0');
      final names = images
          ? [
              for (final ext in ['png', 'jpg', 'webp']) ...[
                '$n.$ext',
                '$page.$ext',
                'page_$n.$ext',
              ],
            ]
          : qcf
          ? ['QCF4_$n.woff']
          : [
              'QCF_P$n.woff',
              'qcf_p$n.woff',
              'qpc_page_$n.ttf',
              'qpc_page_$n.TTF',
              'qpc_v1_page_$n.ttf',
              'qpc_page_$page.ttf',
              '$n.ttf',
            ];
      if (!names.any((name) {
        final file = files[name];
        if (file == null) return false;
        final handle = file.openSync();
        try {
          final size = handle.lengthSync();
          final header = handle.readSync(48);
          if (images) {
            if (!imageHeaderValid(header, size)) return false;
            final signature = ByteData.sublistView(header).getUint32(0);
            if (signature == 0x89504e47) {
              if (size < 45) return false;
              handle.setPositionSync(size - 12);
              final tail = ByteData.sublistView(handle.readSync(12));
              return tail.getUint32(0) == 0 &&
                  tail.getUint32(4) == 0x49454e44 &&
                  tail.getUint32(8) == 0xae426082;
            }
            if (header[0] == 0xff) {
              handle.setPositionSync(size - 2);
              return ByteData.sublistView(handle.readSync(2)).getUint16(0) ==
                  0xffd9;
            }
            return true;
          }
          if (header.length < 44) return false;
          final data = ByteData.sublistView(header);
          final signature = data.getUint32(0);
          if (signature == 0x774f4646 || signature == 0x774f4632) {
            return data.getUint32(8) == size && data.getUint16(12) > 0;
          }
          return !qcf &&
              (signature == 0x00010000 || signature == 0x4f54544f) &&
              data.getUint16(4) > 0 &&
              12 + 16 * data.getUint16(4) <= size;
        } finally {
          handle.closeSync();
        }
      })) {
        return false;
      }
    }
    dynamic json(String name) =>
        jsonDecode(File('$root/$name').readAsStringSync());
    if (!images) {
      final alignment = json(
        qcf ? 'qcf4_line_alignment.json' : 'qpc_v1_line_alignment.json',
      ) as Map;
      for (var n = 1; n <= 604; n++) {
        final page = alignment[n.toString()];
        if (page is! Map ||
            page.isEmpty ||
            page.values.any((line) => line is! Map || line['c'] is! int)) {
          return false;
        }
      }
    }
    if (qcf) {
      final pages = json('quran_glyphs.json') as List;
      if (pages.length != 604) return false;
      for (int i = 0; i < pages.length; i++) {
        final page = PageGlyph.fromJson(pages[i]);
        if (page.page != i + 1 ||
            page.lines.isEmpty ||
            !page.lines.any((l) => l.glyphs.isNotEmpty)) {
          return false;
        }
      }
    } else if (images) {
      final pages = json('shamerly_quran_complete.json')['pages'] as List;
      final ids = {
        for (final page in pages)
          if (page['ayahs'] is List) page['page'],
      };
      for (var n = 2; n <= 522; n++) {
        if (!ids.contains(n)) return false;
      }
    } else {
      final glyphs = json('qpc_v1_glyphs.json') as Map;
      final layout = json('qpc_v1_layout.json') as Map;
      if (glyphs.isEmpty ||
          glyphs.values.any((v) => v is! Map || v['text'] is! String)) {
        return false;
      }
      for (var n = 1; n <= 604; n++) {
        final lines = layout[n.toString()];
        if (lines is! List || lines.isEmpty) return false;
        for (final line in lines) {
          if (line is! List) return false;
          for (final item in line) {
            if (item is! Map) return false;
            if (item['t'] == 1 &&
                !glyphs.containsKey('${item['s']}:${item['a']}:${item['w']}')) {
              return false;
            }
          }
        }
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

bool imageHeaderValid(Uint8List bytes, int length) {
  if (bytes.length < 12 || length < 16) return false;
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(0) == 0x89504e47 && data.getUint32(4) == 0x0d0a1a0a) ||
      (data.getUint16(0) == 0xffd8 && bytes[2] == 0xff) ||
      (data.getUint32(0) == 0x52494646 &&
          data.getUint32(8) == 0x57454250 &&
          data.getUint32(4, Endian.little) + 8 == length);
}
