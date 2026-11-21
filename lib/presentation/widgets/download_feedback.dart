import 'package:material_ui/material_ui.dart';

Future<void> showDownloadFailure(
  BuildContext context,
  Future<void> download,
) async {
  try {
    await download;
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تعذّر إكمال التنزيل. $error')));
  }
}
