import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

import 'recitation_result_view.dart';

typedef _ReviewLocation = ({
  RecitationReviewKind kind,
  int surahNumber,
  int ayahNumber,
  int wordIndex,
});

typedef _ReviewOccurrence = ({
  RecitationResult result,
  RecitationReviewItem item,
  DateTime date,
});

class RecitationErrorReviewView extends StatefulWidget {
  const RecitationErrorReviewView({super.key, required this.onOpenResult});

  final void Function(RecitationResult result, WordResult word) onOpenResult;

  @override
  State<RecitationErrorReviewView> createState() =>
      _RecitationErrorReviewViewState();
}

class _RecitationErrorReviewViewState extends State<RecitationErrorReviewView> {
  List<({RecitationSession session, String? detail})> _indexedSessions =
      const [];
  Map<_ReviewLocation, List<_ReviewOccurrence>> _groups = const {};
  int _surah = 0;
  RecitationReviewKind? _kind;

  void _indexSessions(List<RecitationSession> sessions) {
    final snapshot = [
      for (final session in sessions)
        (session: session, detail: session.resultJson),
    ];
    if (listEquals(_indexedSessions, snapshot)) return;
    _indexedSessions = snapshot;
    final recentFirst = List.of(sessions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = <_ReviewLocation, List<_ReviewOccurrence>>{};
    for (final session in recentFirst) {
      final result = RecitationResult.fromSession(session);
      final locationsInSession = <_ReviewLocation>{};
      for (final item in result.activeReviewItems) {
        final location = (
          kind: item.kind,
          surahNumber: item.surahNumber,
          ayahNumber: item.ayahNumber,
          wordIndex: item.kind == RecitationReviewKind.skippedAyah
              ? -1
              : item.wordIndex,
        );
        if (locationsInSession.add(location)) {
          groups.putIfAbsent(location, () => []).add((
            result: result,
            item: item,
            date: session.createdAt.toLocal(),
          ));
        }
      }
    }
    _groups = groups;
  }

  @override
  Widget build(BuildContext context) {
    _indexSessions(context.watch<RecitationProvider>().allSessions);
    final surahs = <int, String>{};
    final kinds = <RecitationReviewKind>{};
    for (final entry in _groups.entries) {
      final first = entry.value.first.result;
      final number = entry.key.surahNumber;
      surahs.putIfAbsent(
        number,
        () => recitationSurahName(
          context,
          number,
          fallback: first.surahNumber == number ? first.surahName : '',
        ),
      );
      kinds.add(entry.key.kind);
    }
    final selectedSurah = surahs.containsKey(_surah) ? _surah : 0;
    final selectedKind = kinds.contains(_kind) ? _kind : null;
    final groups =
        _groups.entries
            .where(
              (entry) =>
                  (selectedSurah == 0 ||
                      entry.key.surahNumber == selectedSurah) &&
                  (selectedKind == null
                      ? entry.key.kind.isIssue
                      : entry.key.kind == selectedKind),
            )
            .toList()
          ..sort((a, b) {
            final byCount = b.value.length.compareTo(a.value.length);
            return byCount != 0
                ? byCount
                : b.value.first.date.compareTo(a.value.first.date);
          });

    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  value: selectedSurah,
                  isExpanded: true,
                  onChanged: (value) => setState(() => _surah = value ?? 0),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('كل السور')),
                    for (final number in surahs.keys.toList()..sort())
                      DropdownMenuItem(
                        value: number,
                        child: Text(
                          surahs[number]!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<int>(
                  value: selectedKind == null ? 0 : selectedKind.index + 1,
                  isExpanded: true,
                  onChanged: (value) => setState(() {
                    _kind = value == null || value == 0
                        ? null
                        : RecitationReviewKind.values[value - 1];
                  }),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('كل الأخطاء')),
                    for (final kind in RecitationReviewKind.values)
                      if (kinds.contains(kind))
                        DropdownMenuItem(
                          value: kind.index + 1,
                          child: Text(
                            kind.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    _groups.isEmpty
                        ? 'لا توجد مواضع للمراجعة بعد'
                        : 'لا توجد نتائج بهذا التصنيف',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = groups[index];
                    final first = entry.value.first;
                    final category = entry.key.kind;
                    final word = first.item.word.expectedWord.trim();
                    final title =
                        category == RecitationReviewKind.skippedAyah ||
                            word.isEmpty
                        ? category.label
                        : word;
                    final contextLabel =
                        '${surahs[entry.key.surahNumber]} · الآية ${entry.key.ayahNumber}';
                    final date = localizations.formatCompactDate(first.date);
                    final attempts = entry.value.length;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        onTap: () =>
                            widget.onOpenResult(first.result, first.item.word),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontFamily: title == word
                                ? 'KFGQPC_HAFS'
                                : 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contextLabel),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 10,
                                runSpacing: 2,
                                children: [
                                  if (title != category.label)
                                    Text(category.label),
                                  Text(
                                    attempts == 1
                                        ? date
                                        : '$attempts جلسات · آخرها $date',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_left_rounded,
                          color: scheme.brightness == Brightness.dark
                              ? AppColors.brandGold
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
