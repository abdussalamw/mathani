import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

import 'recitation_result_view.dart';

enum _HistoryPeriod {
  today('اليوم'),
  week('آخر 7 أيام'),
  all('الكل');

  const _HistoryPeriod(this.label);
  final String label;
}

class RecitationHistoryView extends StatefulWidget {
  const RecitationHistoryView({super.key, required this.onOpenResult});

  final ValueChanged<RecitationResult> onOpenResult;

  @override
  State<RecitationHistoryView> createState() => _RecitationHistoryViewState();
}

class _RecitationHistoryViewState extends State<RecitationHistoryView> {
  final _scroll = ScrollController();
  _HistoryPeriod _period = _HistoryPeriod.all;
  DateTime? _date;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _chooseDay(
    List<RecitationSession> sessions,
    DateTime today,
  ) async {
    final days = sessions.map((s) => DateUtils.dateOnly(s.createdAt.toLocal()));
    var earliest = today;
    var latest = today;
    for (final day in days) {
      if (day.isBefore(earliest)) earliest = day;
      if (day.isAfter(latest)) latest = day;
    }
    final selected = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDate: _date ?? today,
      helpText: 'تاريخ التسميع',
    );
    if (!mounted || selected == null) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _date = selected);
  }

  bool _includes(DateTime day, DateTime today) {
    if (_date != null) return DateUtils.isSameDay(day, _date);
    return switch (_period) {
      _HistoryPeriod.today => day == today,
      _HistoryPeriod.week =>
        !day.isBefore(DateTime(today.year, today.month, today.day - 6)) &&
            !day.isAfter(today),
      _HistoryPeriod.all => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<RecitationProvider>().allSessions;
    final localizations = MaterialLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final matching =
        sessions
            .where(
              (s) =>
                  _includes(DateUtils.dateOnly(s.createdAt.toLocal()), today),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final rows = <({DateTime day, RecitationSession? session})>[];
    DateTime? previousDay;
    for (final session in matching) {
      final day = DateUtils.dateOnly(session.createdAt.toLocal());
      if (day != previousDay) {
        rows.add((day: day, session: null));
        previousDay = day;
      }
      rows.add((day: day, session: session));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final period in _HistoryPeriod.values)
                ChoiceChip(
                  label: Text(period.label),
                  selected: _date == null && _period == period,
                  onSelected: (_) {
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                    setState(() {
                      _period = period;
                      _date = null;
                    });
                  },
                ),
              OutlinedButton.icon(
                onPressed: () => _chooseDay(sessions, today),
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _date == null
                      ? 'اختيار تاريخ'
                      : localizations.formatCompactDate(_date!),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    sessions.isEmpty
                        ? 'لا توجد تسميعات سابقة'
                        : 'لا توجد جلسات في الفترة المختارة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final session = row.session;
                    if (session != null) {
                      return _sessionCard(context, session, localizations);
                    }
                    final heading = localizations.formatFullDate(row.day);
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: Semantics(
                        header: true,
                        child: Text(
                          heading,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sessionCard(
    BuildContext context,
    RecitationSession session,
    MaterialLocalizations localizations,
  ) {
    final result = RecitationResult.fromSession(session);
    final scheme = Theme.of(context).colorScheme;
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(session.createdAt.toLocal()),
    );
    final duration = Duration(seconds: session.durationSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onOpenResult(result),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    recitationSurahName(
                      context,
                      result.surahNumber,
                      fallback: result.surahName,
                    ),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(time, style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                recitationRangeLabel(context, result),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '$minutes:$seconds',
                    textDirection: TextDirection.ltr,
                    semanticsLabel:
                        '$minutes دقيقة و${duration.inSeconds.remainder(60)} ثانية',
                  ),
                  if (session.totalWords > 0)
                    Text(
                      '${session.correctWords} من ${session.totalWords} مقيّمة',
                    ),
                  if (result.words.isNotEmpty) ...[
                    Text('الأخطاء ${result.reviewIssueCount}'),
                    if (result.unconfirmedWords > 0)
                      Text('غير مؤكدة ${result.unconfirmedWords}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
