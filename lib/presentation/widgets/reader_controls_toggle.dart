import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/ui_provider.dart';

class ReaderControlsToggle extends StatelessWidget {
  const ReaderControlsToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final hidden = context.select<UiProvider, bool>((ui) => ui.isImmersiveMode);
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .92),
      elevation: 2,
      shape: const CircleBorder(),
      child: IconButton(
        key: const ValueKey('reader-controls-toggle'),
        tooltip: hidden
            ? 'إظهار الشريطين العلوي والسفلي'
            : 'إخفاء الأشرطة للقراءة الكاملة',
        onPressed: context.read<UiProvider>().toggleImmersiveMode,
        color: AppColors.brandGold,
        icon: Icon(
          hidden ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        ),
      ),
    );
  }
}
