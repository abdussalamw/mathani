import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/screens/recitation/recitation_screen.dart';

class _HistoryProvider extends ChangeNotifier implements RecitationProvider {
  _HistoryProvider(this.allSessions);

  @override
  final List<RecitationSession> allSessions;

  @override
  RecitationState get state => RecitationState.setup;

  @override
  bool get isSheikhPlaying => false;

  @override
  Future<void> stopUserAudio() async {}

  @override
  Future<void> stopSheikhAudio() async {}

  @override
  Future<RecitationResult> setReviewItemDismissed(
    RecitationResult result,
    RecitationReviewItem item, {
    required bool dismissed,
  }) async {
    final session = allSessions.singleWhere(
      (row) => row.id == result.sessionId,
    );
    final updated = RecitationResult.updateSessionReview(
      session,
      item,
      dismissed: dismissed,
    );
    notifyListeners();
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RecitationSession _session({
  required DateTime date,
  required String name,
  int surah = 17,
  List<WordResult> words = const [],
}) {
  final result = RecitationResult(
    words: words,
    surahNumber: surah,
    surahName: name,
    startAyah: 28,
    endAyah: 30,
    durationMs: 37000,
    rawTranscript: '',
    analyzedAt: date,
  );
  return RecitationSession()
    ..surahNumber = surah
    ..surahName = name
    ..startAyah = 28
    ..endAyah = 30
    ..durationSeconds = 37
    ..createdAt = date
    ..correctWords = result.correctWords
    ..totalWords = result.gradedWords
    ..resultJson = jsonEncode(result.toJson());
}

Widget _browse(
  List<RecitationSession> sessions, {
  RecitationTab initialTab = RecitationTab.history,
}) {
  return ChangeNotifierProvider<RecitationProvider>(
    create: (_) => _HistoryProvider(sessions),
    child: MaterialApp(
      home: Scaffold(body: RecitationScreen(initialTab: initialTab)),
    ),
  );
}

void main() {
  testWidgets(
    'history lists sessions beyond the three most recent and keeps its filter',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sessions = [
        for (var i = 0; i < 4; i++)
          _session(
            date: today.add(Duration(minutes: 10 * i)),
            name: 'جلسة اليوم ${i + 1}',
          ),
        _session(
          date: DateTime(today.year, today.month, today.day - 8),
          name: 'جلسة قديمة',
        ),
      ];
      await tester.pumpWidget(_browse(sessions));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('جلسة قديمة'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('جلسة قديمة'), findsOneWidget);

      await tester.tap(find.text('اليوم'));
      await tester.pumpAndSettle();
      expect(find.text('جلسة قديمة'), findsNothing);

      await tester.tap(find.text('جلسة اليوم 4'));
      await tester.pumpAndSettle();
      expect(find.text('نتيجة التسميع'), findsOneWidget);

      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      final todayChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'اليوم'),
      );
      expect(todayChip.selected, true);
      expect(find.text('جلسة اليوم 4'), findsOneWidget);
      expect(find.text('جلسة قديمة'), findsNothing);
    },
  );

  testWidgets(
    'review groups repeated mistakes and opens the same ayah context',
    (tester) async {
      const missedWord = WordResult(
        spokenWord: '',
        expectedWord: 'مَحْسُورًا',
        surahNumber: 17,
        ayahNumber: 29,
        wordIndex: 6,
        verdict: WordVerdict.skipped,
        reviewKind: RecitationReviewKind.skippedWord,
      );
      const nextWord = WordResult(
        spokenWord: '',
        expectedWord: 'مُلُومًا',
        surahNumber: 17,
        ayahNumber: 29,
        wordIndex: 5,
        verdict: WordVerdict.correct,
      );
      const uncertainWord = WordResult(
        spokenWord: '',
        expectedWord: 'بَصِيرًا',
        surahNumber: 17,
        ayahNumber: 30,
        wordIndex: 7,
        verdict: WordVerdict.unconfirmed,
      );
      final date = DateTime.now();
      await tester.pumpWidget(
        _browse([
          _session(
            date: date,
            name: 'الإسراء',
            words: [nextWord, missedWord, uncertainWord],
          ),
          _session(
            date: date.subtract(const Duration(days: 1)),
            name: 'الإسراء',
            words: [missedWord],
          ),
        ], initialTab: RecitationTab.review),
      );
      await tester.pumpAndSettle();

      expect(find.text('مَحْسُورًا'), findsOneWidget);
      expect(find.textContaining('2 جلسات'), findsOneWidget);
      expect(find.text('بَصِيرًا'), findsNothing);

      await tester.tap(find.text('مَحْسُورًا'));
      await tester.pumpAndSettle();
      expect(find.text('نتيجة التسميع'), findsOneWidget);
      expect(find.text('الإسراء · الآية 29'), findsWidgets);
      expect(find.text('مُلُومًا'), findsWidgets);
      expect(find.textContaining('تجاوز كلمة'), findsWidgets);
    },
  );

  testWidgets('dismissal updates review and history and can be undone', (
    tester,
  ) async {
    const word = WordResult(
      spokenWord: '',
      expectedWord: 'مَحْسُورًا',
      surahNumber: 17,
      ayahNumber: 29,
      wordIndex: 6,
      verdict: WordVerdict.skipped,
      reviewKind: RecitationReviewKind.skippedWord,
    );
    final session = _session(
      date: DateTime.now(),
      name: 'الإسراء',
      words: [word],
    )..id = 8;
    await tester.pumpWidget(
      _browse([session], initialTab: RecitationTab.review),
    );
    await tester.pumpAndSettle();
    final target = find.text(word.expectedWord);

    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.ensureVisible(target.first);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('استبعاد التنبيه'));
    await tester.pumpAndSettle();
    expect(find.text('مستبعد من إحصاء الأخطاء'), findsOneWidget);

    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مواضع للمراجعة بعد'), findsOneWidget);

    await tester.tap(find.text('السجل'));
    await tester.pumpAndSettle();
    expect(find.text('الأخطاء 0'), findsOneWidget);
    await tester.tap(find.text('الأخطاء 0'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة احتساب التنبيه'));
    await tester.pumpAndSettle();
    expect(find.text('استبعاد التنبيه'), findsOneWidget);

    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('الأخطاء 1'), findsOneWidget);
    await tester.tap(find.text('مراجعة الأخطاء'));
    await tester.pumpAndSettle();
    expect(target, findsOneWidget);
  });
}
