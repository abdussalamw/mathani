import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

class AyahPressTarget extends StatelessWidget {
  const AyahPressTarget({super.key, required this.child, this.onSelected});

  static const holdDuration = Duration(milliseconds: 350);

  final Widget child;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    if (onSelected == null) return child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: holdDuration),
              (recognizer) => recognizer.onLongPress = onSelected,
            ),
      },
      child: child,
    );
  }
}
