import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/reader_system_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mathani/reader_system_ui');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> nativeCalls;
  late List<MethodCall> platformCalls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    nativeCalls = [];
    platformCalls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'Android sends both reader states to the native status bar policy',
    () async {
      expect(await ReaderSystemUi.setImmersiveMode(true), isTrue);
      expect(await ReaderSystemUi.setImmersiveMode(false), isTrue);
      expect(nativeCalls.map((call) => call.method), [
        'setImmersiveMode',
        'setImmersiveMode',
      ]);
      expect(nativeCalls.map((call) => call.arguments), [true, false]);
      expect(platformCalls, isEmpty);
    },
  );

  test(
    'other platforms preserve the bottom system overlay in both modes',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await ReaderSystemUi.setImmersiveMode(true), isTrue);
      expect(await ReaderSystemUi.setImmersiveMode(false), isTrue);
      expect(nativeCalls, isEmpty);
      expect(platformCalls.map((call) => call.method), [
        'SystemChrome.setEnabledSystemUIOverlays',
        'SystemChrome.setEnabledSystemUIOverlays',
      ]);
      expect(platformCalls.map((call) => call.arguments), [
        ['SystemUiOverlay.bottom'],
        ['SystemUiOverlay.top', 'SystemUiOverlay.bottom'],
      ]);
    },
  );

  test(
    'missing Android plugin reports fallback and preserves system navigation',
    () async {
      messenger.setMockMethodCallHandler(channel, null);
      expect(await ReaderSystemUi.setImmersiveMode(true), isFalse);
      expect(await ReaderSystemUi.setImmersiveMode(false), isFalse);
      expect(platformCalls.map((call) => call.arguments), [
        ['SystemUiOverlay.bottom'],
        ['SystemUiOverlay.top', 'SystemUiOverlay.bottom'],
      ]);
    },
  );

  test('native failures stay visible to the caller', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'status_bar_failed');
    });
    await expectLater(
      ReaderSystemUi.setImmersiveMode(true),
      throwsA(isA<PlatformException>()),
    );
    expect(platformCalls, isEmpty);
  });
}
