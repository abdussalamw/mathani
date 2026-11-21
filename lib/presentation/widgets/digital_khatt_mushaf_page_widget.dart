import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/digital_khatt_page_loader.dart';
import '../../data/models/recitation_result.dart';
import '../../l10n/app_localizations.dart';
import 'ayah_press_target.dart';
import 'reader_loading_indicator.dart';

class DigitalKhattMushafPageWidget extends StatefulWidget {
  const DigitalKhattMushafPageWidget({
    super.key,
    required this.pageNumber,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahLongPress,
    this.wordVerdicts = const {},
    this.fontFamily = 'DigitalKhattMadina',
    this.loader,
  });

  final int pageNumber;
  final int? selectedSurah;
  final int? selectedAyah;
  final void Function(int surah, int ayah)? onAyahLongPress;
  final Map<String, WordVerdict> wordVerdicts;
  final String fontFamily;
  final DigitalKhattPageLoader? loader;

  @override
  State<DigitalKhattMushafPageWidget> createState() => _DigitalKhattPageState();
}

class _DigitalKhattPageState extends State<DigitalKhattMushafPageWidget> {
  late Future<List<MadinaLine>> _page;

  DigitalKhattPageLoader get _loader => widget.loader ?? digitalKhattPageLoader;

  @override
  void initState() {
    super.initState();
    _page = _loader.loadPage(widget.pageNumber);
  }

  @override
  void didUpdateWidget(DigitalKhattMushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.loader != widget.loader) {
      _page = _loader.loadPage(widget.pageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MadinaLine>>(
      future: _page,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ReaderLoadingIndicator();
        }
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.errorLoading),
                TextButton(
                  onPressed: () => setState(
                    () => _page = digitalKhattPageLoader.loadPage(
                      widget.pageNumber,
                    ),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }
        final lines = snapshot.requireData;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final slot = bounds.maxHeight / lines.length;
              final size = math.min(bounds.maxWidth / 15, slot / 1.65);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final line in lines)
                    SizedBox(
                      height: slot,
                      width: bounds.maxWidth,
                      child: _MadinaTextLine(
                        key: ObjectKey(line),
                        line: line,
                        width: bounds.maxWidth,
                        fontSize: size,
                        color: dark ? AppColors.darkText : AppColors.darkBrown,
                        selectedSurah: widget.selectedSurah,
                        selectedAyah: widget.selectedAyah,
                        onAyahLongPress: widget.onAyahLongPress,
                        wordVerdicts: widget.wordVerdicts,
                        fontFamily: widget.fontFamily,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MadinaTextLine extends StatefulWidget {
  const _MadinaTextLine({
    super.key,
    required this.line,
    required this.width,
    required this.fontSize,
    required this.color,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.onAyahLongPress,
    required this.wordVerdicts,
    required this.fontFamily,
  });
  final MadinaLine line;
  final double width;
  final double fontSize;
  final Color color;
  final int? selectedSurah;
  final int? selectedAyah;
  final void Function(int, int)? onAyahLongPress;
  final Map<String, WordVerdict> wordVerdicts;
  final String fontFamily;

  @override
  State<_MadinaTextLine> createState() => _MadinaTextLineState();
}

class _MadinaTextLineState extends State<_MadinaTextLine> {
  final _presses = <int, LongPressGestureRecognizer>{};

  TextSpan _verseSpan(MadinaVerseRun run, int index) {
    final lead = index == 0 ? '' : ' ';
    final style =
        run.surah == widget.selectedSurah && run.ayah == widget.selectedAyah
        ? TextStyle(backgroundColor: AppColors.golden.withValues(alpha: .2))
        : null;
    final press = run.ayah == 0 || widget.onAyahLongPress == null
        ? null
        : (_presses.putIfAbsent(
              index,
              () => LongPressGestureRecognizer(
                duration: AyahPressTarget.holdDuration,
              ),
            )
            ..onLongPress = () =>
                widget.onAyahLongPress?.call(run.surah, run.ayah));
    if (widget.wordVerdicts.isEmpty || run.ayah == 0) {
      return TextSpan(text: lead + run.text, style: style, recognizer: press);
    }
    final words = run.text.split(' ');
    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i < words.length; i++)
          TextSpan(
            text: (i == 0 ? lead : ' ') + words[i],
            recognizer: press,
            style: words[i].startsWith('۝')
                ? null
                : _verdictStyle(
                    widget
                        .wordVerdicts['${run.surah}_${run.ayah}_${run.firstWord + i}'],
                  ),
          ),
      ],
    );
  }

  TextStyle? _verdictStyle(WordVerdict? verdict) {
    final color = switch (verdict) {
      WordVerdict.correct => Colors.green,
      WordVerdict.incorrect => Colors.red,
      WordVerdict.acceptable || WordVerdict.skipped => Colors.orange,
      WordVerdict.unconfirmed || null => null,
    };
    return color == null
        ? null
        : TextStyle(backgroundColor: color.withValues(alpha: .18));
  }

  @override
  void dispose() {
    for (final press in _presses.values) {
      press.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runs = widget.line.runs;
    final text = runs.map((run) => run.text).join(' ');
    final isBasmala = runs.first.ayah == 0 && text.startsWith('بِسْمِ');
    var style = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: widget.fontSize,
      height: 1.65,
      color: widget.color,
      fontFeatures: isBasmala ? const [FontFeature.enable('basm')] : null,
    );
    // Shape each complete line in one RTL paragraph. Spacing only changes the
    // gaps between words. Constrained lines scale down uniformly to fit.
    final naturalWidth = TextPainter.computeWidth(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    );
    final gaps = ' '.allMatches(text).length;
    if (!widget.line.centered && gaps > 0) {
      style = style.copyWith(
        wordSpacing: math.max(0, (widget.width - naturalWidth) / gaps),
      );
    }
    final spacedWidth = style.wordSpacing == null || style.wordSpacing == 0
        ? naturalWidth
        : TextPainter.computeWidth(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.rtl,
          );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        // Fractional advances can round up when Flutter lays out the paragraph.
        width: math.max(widget.width, spacedWidth).ceilToDouble() + 1,
        child: RichText(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          text: TextSpan(
            style: style,
            children: [
              for (int i = 0; i < runs.length; i++) _verseSpan(runs[i], i),
            ],
          ),
        ),
      ),
    );
  }
}
