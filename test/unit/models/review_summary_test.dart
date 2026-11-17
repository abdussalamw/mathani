import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/domain/entities/review_summary.dart';

void main() {
  final now = DateTime(2026, 11, 17, 12);
  RecitationSession session(int surah, int day, int accuracy) =>
      RecitationSession()
        ..surahNumber = surah
        ..surahName = 'سورة $surah'
        ..createdAt = DateTime(2026, 11, day, 10)
        ..accuracyPercent = accuracy
        ..durationSeconds = 120;

  test(
    'weekly counts include seven calendar days and compare the previous week',
    () {
      final summary = ReviewSummary.fromSessions([
        session(1, 11, 80),
        session(2, 17, 100),
        session(2, 17, 90),
        session(3, 10, 60),
        session(4, 18, 1),
      ], now: now);
      expect(summary.sessions, 3);
      expect(summary.activeDays, 2);
      expect(summary.durationSeconds, 360);
      expect(summary.averageAccuracy, 90);
      expect(summary.accuracyChange, 30);
    },
  );

  test(
    'suggestions use the latest session for each surah instead of old mistakes',
    () {
      final summary = ReviewSummary.fromSessions([
        session(1, 10, 20),
        session(1, 16, 95),
        session(2, 15, 70),
        session(3, 12, 80),
      ], now: now);
      expect(summary.suggestedReview?.surahNumber, 2);
    },
  );

  test('empty history does not invent improvement or a recommendation', () {
    final summary = ReviewSummary.fromSessions([], now: now);
    expect(summary.sessions, 0);
    expect(summary.accuracyChange, isNull);
    expect(summary.suggestedReview, isNull);
  });
}
