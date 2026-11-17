import '../../data/models/recitation_session.dart';

class ReviewSummary {
  final int sessions;
  final int activeDays;
  final int durationSeconds;
  final int averageAccuracy;
  final int? accuracyChange;
  final RecitationSession? suggestedReview;

  const ReviewSummary({
    required this.sessions,
    required this.activeDays,
    required this.durationSeconds,
    required this.averageAccuracy,
    required this.accuracyChange,
    required this.suggestedReview,
  });

  factory ReviewSummary.fromSessions(
    Iterable<RecitationSession> sessions, {
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).toLocal();
    final start = DateTime(today.year, today.month, today.day - 6);
    final previousStart = DateTime(today.year, today.month, today.day - 13);
    final current = <RecitationSession>[];
    final previous = <RecitationSession>[];
    final latest = <int, RecitationSession>{};
    for (final session in sessions) {
      if (session.createdAt.isAfter(today) ||
          session.surahNumber < 1 ||
          session.surahNumber > 114) {
        continue;
      }
      final date = session.createdAt.toLocal();
      if (!date.isBefore(start)) {
        current.add(session);
      } else if (!date.isBefore(previousStart)) {
        previous.add(session);
      }
      final last = latest[session.surahNumber];
      if (last == null || date.isAfter(last.createdAt)) {
        latest[session.surahNumber] = session;
      }
    }
    int average(List<RecitationSession> values) => values.isEmpty
        ? 0
        : (values.fold<int>(
                    0,
                    (sum, s) => sum + s.accuracyPercent.clamp(0, 100),
                  ) /
                  values.length)
              .round();
    final reviews = latest.values.where((s) => s.accuracyPercent < 85).toList()
      ..sort((a, b) {
        final accuracy = a.accuracyPercent.compareTo(b.accuracyPercent);
        return accuracy != 0 ? accuracy : a.createdAt.compareTo(b.createdAt);
      });
    return ReviewSummary(
      sessions: current.length,
      activeDays: current
          .map((s) {
            final d = s.createdAt.toLocal();
            return DateTime(d.year, d.month, d.day);
          })
          .toSet()
          .length,
      durationSeconds: current.fold(
        0,
        (sum, s) => sum + s.durationSeconds.clamp(0, 86400),
      ),
      averageAccuracy: average(current),
      accuracyChange: current.isEmpty || previous.isEmpty
          ? null
          : average(current) - average(previous),
      suggestedReview: reviews.isEmpty ? null : reviews.first,
    );
  }
}
