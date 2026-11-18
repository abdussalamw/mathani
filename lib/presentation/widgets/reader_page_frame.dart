import 'package:material_ui/material_ui.dart';

/// Keeps the normal reading rectangle when system/app bars are hidden.
class ReaderPageFrame extends StatefulWidget {
  const ReaderPageFrame({
    super.key,
    required this.immersive,
    required this.child,
  });

  final bool immersive;
  final Widget child;

  @override
  State<ReaderPageFrame> createState() => _ReaderPageFrameState();
}

class _ReaderPageFrameState extends State<ReaderPageFrame> {
  double? _normalChromeHeight;
  EdgeInsets? _normalPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!widget.immersive || _normalChromeHeight == null) {
          _normalChromeHeight = media.size.height - constraints.maxHeight;
          _normalPadding = media.padding;
        }
        final height = (media.size.height - _normalChromeHeight!).clamp(
          0.0,
          constraints.maxHeight,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: MediaQuery(
              data: media.copyWith(padding: _normalPadding),
              child: SafeArea(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
