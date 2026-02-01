import 'package:flutter/material.dart';
import '../mushaf/mushaf_selection_screen.dart';

/// شاشة إعدادات المصاحف
/// تستخدم نفس شاشة اختيار المصاحف الموجودة
class MushafSettingsScreen extends StatelessWidget {
  const MushafSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // نستخدم نفس شاشة المصاحف الموجودة
    return const MushafSelectionScreen();
  }
}
