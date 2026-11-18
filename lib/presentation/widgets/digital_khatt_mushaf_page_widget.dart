import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/digital_khatt_page_loader.dart';
import '../providers/settings_provider.dart';

class DigitalKhattMushafPageWidget extends StatefulWidget {
  final int pageNumber;

  const DigitalKhattMushafPageWidget({super.key, required this.pageNumber});

  @override
  State<DigitalKhattMushafPageWidget> createState() =>
      _DigitalKhattMushafPageWidgetState();
}

class _DigitalKhattMushafPageWidgetState
    extends State<DigitalKhattMushafPageWidget> {
  late Future<String> _pageSvg;

  @override
  void initState() {
    super.initState();
    _pageSvg = digitalKhattPageLoader.loadPage(widget.pageNumber);
  }

  @override
  void didUpdateWidget(DigitalKhattMushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _pageSvg = digitalKhattPageLoader.loadPage(widget.pageNumber);
    }
  }

  void _retry() {
    setState(() {
      _pageSvg = digitalKhattPageLoader.loadPage(widget.pageNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pageSvg,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return _buildError(snapshot.error!);
        }

        return Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return ColoredBox(
              color: settings.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    Widget page = SvgPicture.string(
                      snapshot.data!,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      semanticsLabel:
                          'صفحة ${widget.pageNumber} من مصحف المدينة 1441',
                      errorBuilder: (context, error, stackTrace) =>
                          _buildError(error),
                    );

                    if (settings.isDarkMode) {
                      page = ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: page,
                      );
                    } else if (settings.backgroundColorMode != 'white') {
                      page = ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          settings.backgroundColor,
                          BlendMode.multiply,
                        ),
                        child: page,
                      );
                    }

                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: page,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'تعذّر تحميل صفحة المصحف. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
