import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════
/// نظام التخطيط المحكم للمصحف - النسخة المدمجة (Compact & Safe)
/// ═══════════════════════════════════════════════════════════════════
///
/// التعديلات بناءً على طلب المستخدم:
/// 1. "رفع الصفحة": تقليل الهامش العلوي والشريط العلوي لأقصى حد.
/// 2. "حماية السطر 15": زيادة الهامش السفلي لضمان عدم تغطيته.
///
class ResponsiveConstants {
  // ═══════════════════════════════════════════════════════════════════
  // الثوابت الأساسية
  // ═══════════════════════════════════════════════════════════════════

  static const int linesPerPage = 15;

  // هامش أمان: مسافة ملغاة علوية لتلتصق الشاشة بالشريط العلوي، وزيادة السفلي لحمايته
  static const double safetyMarginTop =
      0.0; // 0px (لرفع السطر الأول للأعلى تماماً)
  static const double safetyMarginBottom = 40.0; // 40px (حماية قوية للسطر 15)
  static const double totalSafetyMargin = safetyMarginTop + safetyMarginBottom;

  // ═══════════════════════════════════════════════════════════════════
  // الحدود الدنيا والعليا (Safe Values)
  // ═══════════════════════════════════════════════════════════════════

  // الشريط العلوي: 45px (مدمج جداً)
  static const double minTopBarHeight = 45.0;
  static const double maxTopBarHeight = 80.0;

  // الشريط السفلي: 80px -> 120px
  static const double minBottomBarHeight = 80.0;
  static const double maxBottomBarHeight = 120.0;

  static const double minContentHeight = 400.0;

  // ═══════════════════════════════════════════════════════════════════
  // النسب المئوية (عودة للقيم الصغيرة للجوال)
  // ═══════════════════════════════════════════════════════════════════

  static const double mobileTopBarRatio = 0.055; // 5.5% (صغير)
  static const double mobileBottomBarRatio = 0.10; // 10%

  static const double tabletTopBarRatio = 0.07; // 7%
  static const double tabletBottomBarRatio = 0.10; // 10%

  static const double desktopTopBarRatio = 0.07; // 7%
  static const double desktopBottomBarRatio = 0.11; // 11%

  // ═══════════════════════════════════════════════════════════════════
  // المنطق
  // ═══════════════════════════════════════════════════════════════════

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.mobile;
    if (width < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static double getTopBarRatio(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobileTopBarRatio;
      case DeviceType.tablet:
        return tabletTopBarRatio;
      case DeviceType.desktop:
        return desktopTopBarRatio;
    }
  }

  static double getBottomBarRatio(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobileBottomBarRatio;
      case DeviceType.tablet:
        return tabletBottomBarRatio;
      case DeviceType.desktop:
        return desktopBottomBarRatio;
    }
  }

  /// حساب ارتفاع الشريط العلوي
  static double getTopBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).viewPadding.top; // Stable padding

    final calculated = screenHeight * getTopBarRatio(context);

    // نضمن أن الشريط يكفي الـ Status Bar + المحتوى (45px)
    return max(
      calculated,
      minTopBarHeight + padding,
    ).clamp(minTopBarHeight + padding, maxTopBarHeight + padding);
  }

  /// حساب ارتفاع الشريط السفلي
  static double getBottomBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).viewPadding.bottom; // Stable padding

    final calculated = screenHeight * getBottomBarRatio(context);

    return max(
      calculated,
      minBottomBarHeight + padding,
    ).clamp(minBottomBarHeight + padding, maxBottomBarHeight + padding);
  }

  // بقية الدوال كما هي
  static double getContentHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topBar = getTopBarHeight(context);
    final bottomBar = getBottomBarHeight(context);

    final calculated = screenHeight - topBar - bottomBar - totalSafetyMargin;
    return max(calculated, minContentHeight);
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    final topBar = getTopBarHeight(context);
    final bottomBar = getBottomBarHeight(context);

    return EdgeInsets.only(
      top: topBar + safetyMarginTop,
      bottom: bottomBar + safetyMarginBottom,
      left: 16.0,
      right: 16.0,
    );
  }

  static void printLayoutReport(BuildContext context) {
    if (!kDebugMode) return;

    final topBar = getTopBarHeight(context);
    final bottomBar = getBottomBarHeight(context);
    final content = getContentHeight(context);
    final viewPadding = MediaQuery.of(context).viewPadding;

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint(
      '📐 Layout (Compact): Top=${topBar.toStringAsFixed(1)}, Bottom=${bottomBar.toStringAsFixed(1)}',
    );
    debugPrint('   ViewPadding: T=${viewPadding.top}, B=${viewPadding.bottom}');
    debugPrint(
      '   Content=${content.toStringAsFixed(1)} (Margin: Top=$safetyMarginTop, Bot=$safetyMarginBottom)',
    );
    debugPrint('═══════════════════════════════════════════════════');
  }

  static LayoutValidation validateLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final total =
        getTopBarHeight(context) +
        getContentHeight(context) +
        getBottomBarHeight(context) +
        totalSafetyMargin;
    return LayoutValidation(
      isValid: total <= screenHeight + 2,
      topBarHeight: getTopBarHeight(context),
      bottomBarHeight: getBottomBarHeight(context),
      contentHeight: getContentHeight(context),
      totalHeight: total,
      screenHeight: screenHeight,
      deviceType: getDeviceType(context),
    );
  }
}

// ... (Helper classes)
enum DeviceType { mobile, tablet, desktop }

class LayoutValidation {
  final bool isValid;
  final double topBarHeight;
  final double bottomBarHeight;
  final double contentHeight;
  final double totalHeight;
  final double screenHeight;
  final DeviceType deviceType;

  const LayoutValidation({
    required this.isValid,
    required this.topBarHeight,
    required this.bottomBarHeight,
    required this.contentHeight,
    required this.totalHeight,
    required this.screenHeight,
    required this.deviceType,
  });

  String? getWarningMessage() => isValid ? null : 'Layout Invalid';
}
