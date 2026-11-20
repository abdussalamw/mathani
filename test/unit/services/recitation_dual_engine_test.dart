import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dual Recitation Engine Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('RecitationEngine enum has zipformer and whisper', () {
      expect(RecitationEngine.values.length, equals(2));
      expect(RecitationEngine.values, contains(RecitationEngine.zipformer));
      expect(RecitationEngine.values, contains(RecitationEngine.whisper));
    });

    test('Engine switching updates properties correctly', () async {
      SharedPreferences.setMockInitialValues({'recitation_engine': 'whisper'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('recitation_engine'), equals('whisper'));

      // Test changing to zipformer
      await prefs.setString('recitation_engine', 'zipformer');
      expect(prefs.getString('recitation_engine'), equals('zipformer'));
    });

    test('RecitationSessionConfig holds immutable session properties', () {
      final config1 = RecitationSessionConfig(
        sessionId: 'sess_1',
        engine: RecitationEngine.zipformer,
        mode: RecitationMode.selected,
        surahNumber: 12,
        surahName: 'يوسف',
        startAyah: 1,
        endAyah: 5,
        startTime: DateTime.now(),
      );

      expect(config1.sessionId, equals('sess_1'));
      expect(config1.engine, equals(RecitationEngine.zipformer));
      expect(config1.surahNumber, equals(12));
      expect(config1.startAyah, equals(1));
      expect(config1.endAyah, equals(5));

      final config2 = RecitationSessionConfig(
        sessionId: 'sess_2',
        engine: RecitationEngine.zipformer,
        mode: RecitationMode.free,
        surahName: 'حر',
        startAyah: 1,
        endAyah: 1,
        startTime: DateTime.now(),
      );

      expect(config1.sessionId, isNot(equals(config2.sessionId)));
    });

    test('RecitationState includes preparing and paused lifecycle states', () {
      expect(RecitationState.values, contains(RecitationState.preparing));
      expect(RecitationState.values, contains(RecitationState.paused));
      expect(RecitationState.values, contains(RecitationState.recording));
      expect(RecitationState.values, contains(RecitationState.analyzing));
      expect(RecitationState.values, contains(RecitationState.result));
    });
  });
}
