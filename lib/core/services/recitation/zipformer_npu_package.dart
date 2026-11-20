import 'dart:io';

import 'package:crypto/crypto.dart';

typedef ZipformerFile = ({String name, int size, String sha256});

/// The exact NPU package verified on SM8650 with QNN EP 2.7.0.
abstract final class ZipformerNpuPackage {
  static const ZipformerFile context = (
    name: 'zipformer-v3-sm8650-softplus_ctx.onnx',
    size: 13204,
    sha256: '4b4f09aadf80a2ff23609111c0e19d8a711ff3a137e1e4c7d2e3b694a266dc41',
  );
  static const ZipformerFile binary = (
    name: 'zipformer-v3-sm8650-softplus_ctx_qnn.bin',
    size: 151097344,
    sha256: 'e596c3753a5f389f495d50b94bfd5bb3ae4037d6b6c0df9332f7184daeccccc3',
  );
  static const ZipformerFile phonemes = (
    name: 'ordered_quran_phonemes.json',
    size: 12827409,
    sha256: 'af54b04918cb46873dc9f7c9bac48be3b9f0a41d57be8f1659cdd2d8f09e5c50',
  );
  static const ZipformerFile tokens = (
    name: 'tokens.txt',
    size: 2597,
    sha256: 'ed1cf15923b96a8c6fb4b2e03791d1ec2e5d09aa2dac99086e1b3175986a581f',
  );

  static Future<bool> matches(File file, ZipformerFile expected) async {
    try {
      if (await file.length() != expected.size) return false;
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString() == expected.sha256;
    } on FileSystemException {
      return false;
    }
  }
}
