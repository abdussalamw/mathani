import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mathani/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';

class ReaderLoadingIndicator extends StatefulWidget {
  const ReaderLoadingIndicator({super.key});

  @override
  State<ReaderLoadingIndicator> createState() => _ReaderLoadingIndicatorState();
}

class _ReaderLoadingIndicatorState extends State<ReaderLoadingIndicator> {
  bool _visible = false;
  late final Timer _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _delay.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingMushaf,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
          ),
        ],
      ),
    );
  }
}
