import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';

WordResult _word(
  int surah,
  int ayah,
  int index,
  WordVerdict verdict, {
  RecitationReviewKind? kind,
}) => WordResult(
  spokenWord: '',
  expectedWord: 'كلمة',
  surahNumber: surah,
  ayahNumber: ayah,
  wordIndex: index,
  verdict: verdict,
  reviewKind: kind,
);

void main() {
  test(
    'dismisses one review issue and restores the original payload on undo',
    () {
      final result = RecitationResult(
        words: [
          _word(17, 29, 0, WordVerdict.correct),
          _word(17, 29, 1, WordVerdict.skipped),
          _word(
            17,
            29,
            2,
            WordVerdict.incorrect,
            kind: RecitationReviewKind.replacedWord,
          ),
        ],
        surahNumber: 17,
        surahName: 'الإسراء',
        startAyah: 29,
        endAyah: 29,
        durationMs: 4500,
        rawTranscript: '',
        audioPath: 'recording.wav',
      );
      final original = {
        ...result.toJson(),
        'futureField': [1, 2],
      };
      final session = RecitationSession()
        ..id = 42
        ..correctWords = result.correctWords
        ..totalWords = result.gradedWords
        ..accuracyPercent = result.accuracyPercent
        ..overallGrade = result.overallGrade
        ..resultJson = jsonEncode(original);

      final item = result.reviewItems.first;
      final inMemory = result.withReviewItemDismissal(item, dismissed: true);
      expect(inMemory.sessionId, isNull);
      expect(inMemory.reviewIssueCount, 1);
      expect(result.reviewIssueCount, 2);

      RecitationResult.updateSessionReview(session, item, dismissed: true);
      final reopened = RecitationResult.fromSession(session);
      expect(reopened.sessionId, 42);
      expect(reopened.reviewIssueCount, 1);
      expect(reopened.skippedWords, 0);
      expect(reopened.incorrectWords, 1);
      expect(reopened.isWordReviewDismissed(reopened.words[1]), isTrue);
      expect(reopened.words[1].verdict, WordVerdict.skipped);
      expect(reopened.accuracy, result.accuracy);
      expect(reopened.audioPath, result.audioPath);
      expect(jsonDecode(session.resultJson!)['futureField'], [1, 2]);

      RecitationResult.updateSessionReview(session, item, dismissed: false);
      expect(jsonDecode(session.resultJson!), original);
      expect(RecitationResult.fromSession(session).reviewIssueCount, 2);
    },
  );

  test('typed issues keep a verse skip separate from word grading', () {
    final result = RecitationResult(
      words: [
        _word(17, 29, 0, WordVerdict.correct),
        _word(
          17,
          29,
          1,
          WordVerdict.correct,
          kind: RecitationReviewKind.corrected,
        ),
        _word(
          17,
          29,
          2,
          WordVerdict.skipped,
          kind: RecitationReviewKind.skippedWord,
        ),
        _word(
          17,
          30,
          0,
          WordVerdict.skipped,
          kind: RecitationReviewKind.skippedAyah,
        ),
        _word(
          17,
          30,
          1,
          WordVerdict.skipped,
          kind: RecitationReviewKind.skippedAyah,
        ),
        _word(
          18,
          30,
          0,
          WordVerdict.incorrect,
          kind: RecitationReviewKind.addedWord,
        ),
        _word(18, 30, 1, WordVerdict.unconfirmed),
      ],
      surahNumber: 17,
      surahName: 'الإسراء',
      startAyah: 29,
      endAyah: 30,
      durationMs: 4500,
      rawTranscript: '',
    );

    expect(result.startLocation, (surahNumber: 17, ayahNumber: 29));
    expect(result.endLocation, (surahNumber: 18, ayahNumber: 30));
    expect(
      result.wordsByVerse[(surahNumber: 17, ayahNumber: 30)],
      hasLength(2),
    );
    expect(
      result.wordsByVerse[(surahNumber: 18, ayahNumber: 30)],
      hasLength(2),
    );
    expect(result.reviewIssueCount, 3);
    expect(result.reviewItems.map((item) => item.kind), [
      RecitationReviewKind.corrected,
      RecitationReviewKind.skippedWord,
      RecitationReviewKind.skippedAyah,
      RecitationReviewKind.addedWord,
      RecitationReviewKind.unconfirmed,
    ]);
    final omittedVerse = result.reviewItems[2];
    expect(omittedVerse.count, 1);
    expect(omittedVerse.words, hasLength(2));
    expect(result.gradedWords, 3);
    expect(result.correctWords, 2);
    expect(result.unconfirmedWords, 1);
    expect(result.accuracyPercent, 67);

    final restored = RecitationResult.fromSession(
      RecitationSession()..resultJson = jsonEncode(result.toJson()),
    );
    expect(
      restored.reviewItems.map((item) => item.kind),
      result.reviewItems.map((item) => item.kind),
    );
    expect(restored.endLocation, result.endLocation);
    expect(restored.gradedWords, result.gradedWords);
    expect(restored.correctWords, result.correctWords);
  });

  test(
    'older detailed sessions preserve grades without inventing omissions',
    () {
      final date = DateTime(2026, 11, 21, 10);
      final session = RecitationSession()
        ..surahNumber = 17
        ..surahName = 'الإسراء'
        ..startAyah = 28
        ..endAyah = 30
        ..createdAt = date
        ..durationSeconds = 36
        ..totalWords = 36
        ..correctWords = 35
        ..accuracyPercent = 97
        ..overallGrade = 'ممتاز'
        ..resultJson = jsonEncode({
          'analyzedAt': 'not-a-date',
          'words': [
            _word(17, 29, 0, WordVerdict.skipped).toJson(),
            {
              ..._word(17, 29, 1, WordVerdict.skipped).toJson(),
              'verdict': 'unrecognizedLegacyStatus',
              'startMs': 6500,
              'endMs': 6000,
            },
            99,
            {'surah': 17, 'wordIndex': 0},
          ],
        });

      final result = RecitationResult.fromSession(session);
      expect(result.analyzedAt, date);
      expect(result.durationMs, 36000);
      expect(result.surahName, 'الإسراء');
      expect(result.gradedWords, 36);
      expect(result.correctWords, 35);
      expect(result.accuracyPercent, 97);
      expect(result.overallGrade, 'ممتاز');
      expect(result.words, hasLength(2));
      expect(
        result.words.first.effectiveReviewKind,
        RecitationReviewKind.unclassified,
      );
      expect(result.words.last.verdict, WordVerdict.unconfirmed);
      expect(
        result.words.last.effectiveReviewKind,
        RecitationReviewKind.unconfirmed,
      );
      expect(result.words.last.startTimeMs, isNull);
      expect(result.words.last.endTimeMs, isNull);
      expect(result.reviewIssueCount, 1);
    },
  );

  test(
    'legacy summaries are available when the detail payload is malformed',
    () {
      final session = RecitationSession()
        ..surahNumber = 18
        ..surahName = 'الكهف'
        ..startAyah = 54
        ..endAyah = 56
        ..durationSeconds = 52
        ..totalWords = 42
        ..correctWords = 36
        ..accuracyPercent = 86
        ..overallGrade = 'جيد جداً'
        ..resultJson = '{broken';

      final result = RecitationResult.fromSession(session);
      expect(result.words, isEmpty);
      expect(result.reviewItems, isEmpty);
      expect(result.startLocation, (surahNumber: 18, ayahNumber: 54));
      expect(result.endLocation, (surahNumber: 18, ayahNumber: 56));
      expect(result.durationMs, 52000);
      expect(result.totalWords, 42);
      expect(result.gradedWords, 42);
      expect(result.correctWords, 36);
      expect(result.accuracyPercent, 86);
      expect(result.overallGrade, 'جيد جداً');
    },
  );
}
