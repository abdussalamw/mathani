import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReaderSystemUi {
  static const _channel = MethodChannel('mathani/reader_system_ui');

  /// Returns false when Android's native status bar control is unavailable.
  static Future<bool> setImmersiveMode(bool immersive) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('setImmersiveMode', immersive);
        return true;
      } on MissingPluginException {
        debugPrint(
          'Reader status bar control is unavailable; using system overlays fallback.',
        );
        await _setSystemOverlays(immersive);
        return false;
      }
    }
    await _setSystemOverlays(immersive);
    return true;
  }

  static Future<void> _setSystemOverlays(bool immersive) {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [if (!immersive) SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}
