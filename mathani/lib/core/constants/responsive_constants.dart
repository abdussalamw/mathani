import 'dart:math';
import 'package:flutter/material.dart';

/// ثوابت نظام التخطيط المتجاوب للمصحف
/// يضمن عرضاً متناسقاً على جميع أحجام الشاشات
class ResponsiveConstants {
  // النسب المئوية للأشرطة (الافتراضية - للشاشات العادية)
  static const double defaultTopBarHeightRatio = 0.075;    // 7.5%
  static const double defaultBottomBarHeightRatio = 0.0875; // 8.75%
  static const double defaultContentHeightRatio = 0.8375;   // 83.75%
  
  // النسب المئوية للشاشات الصغيرة (الأولوية للمحتوى)
  static const double smallTopBarHeightRatio = 0.05;    // 5%
  static const double smallBottomBarHeightRatio = 0.05;  // 5%
  static const double smallContentHeightRatio = 0.90;    // 90%
  
  // عدد الأسطر الثابت في كل صفحة
  static const int linesPerPage = 15;
  
  // نسبة الارتفاع/العرض (محسوبة من جوال 400×800)
  // عرض = 400، ارتفاع سطر = (800 × 0.8375) / 15 = 44.67
  // النسبة = 400 / 44.67 = 8.95:1
  static const double aspectRatio = 8.95;
  
  // الحدود الآمنة لارتفاع السطر
  static const double minLineHeight = 40.0;
  static const double maxLineHeight = 60.0;
  
  /// تحديد ما إذا كانت الشاشة صغيرة (تحتاج لتقليل الأشرطة)
  static bool isSmallScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final rawLineHeight = (screenHeight * defaultContentHeightRatio) / linesPerPage;
    return rawLineHeight < minLineHeight;
  }
  
  /// الحصول على النسبة المناسبة للشريط العلوي حسب حجم الشاشة
  static double getTopBarHeightRatio(BuildContext context) {
    return isSmallScreen(context) ? smallTopBarHeightRatio : defaultTopBarHeightRatio;
  }
  
  /// الحصول على النسبة المناسبة للشريط السفلي حسب حجم الشاشة
  static double getBottomBarHeightRatio(BuildContext context) {
    return isSmallScreen(context) ? smallBottomBarHeightRatio : defaultBottomBarHeightRatio;
  }
  
  /// الحصول على النسبة المناسبة للمحتوى حسب حجم الشاشة
  static double getContentHeightRatio(BuildContext context) {
    return isSmallScreen(context) ? smallContentHeightRatio : defaultContentHeightRatio;
  }
  
  /// حساب ارتفاع الشريط العلوي الديناميكي
  static double getTopBarHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * getTopBarHeightRatio(context);
  }
  
  /// حساب ارتفاع الشريط السفلي الديناميكي
  static double getBottomBarHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * getBottomBarHeightRatio(context);
  }
  
  /// حساب ارتفاع منطقة المحتوى
  static double getContentHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * getContentHeightRatio(context);
  }
  
  /// حساب ارتفاع السطر الواحد (مع تطبيق الحدود الآمنة)
  static double getLineHeight(BuildContext context) {
    final contentHeight = getContentHeight(context);
    final rawLineHeight = contentHeight / linesPerPage;
    return rawLineHeight.clamp(minLineHeight, maxLineHeight);
  }
  
  /// حساب العرض المثالي للمحتوى (بناءً على نسبة الارتفاع/العرض)
  static double getIdealContentWidth(BuildContext context) {
    final lineHeight = getLineHeight(context);
    return lineHeight * aspectRatio;
  }
  
  /// حساب العرض النهائي للمحتوى (محدود بعرض الشاشة)
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final idealWidth = getIdealContentWidth(context);
    return min(idealWidth, screenWidth);
  }
  
  /// التحقق من صلاحية الشاشة وإرجاع معلومات التحقق
  static ScreenValidation validateScreen(BuildContext context) {
    final lineHeight = getLineHeight(context);
    final contentWidth = getContentWidth(context);
    final idealWidth = getIdealContentWidth(context);
    final isSmall = isSmallScreen(context);
    
    bool isTooShort = lineHeight <= minLineHeight;
    bool isTooTall = lineHeight >= maxLineHeight;
    bool isAspectDistorted = contentWidth < idealWidth * 0.8;
    
    return ScreenValidation(
      isValid: !isTooShort && !isAspectDistorted,
      isTooShort: isTooShort,
      isTooTall: isTooTall,
      isAspectDistorted: isAspectDistorted,
      isSmallScreen: isSmall,
      lineHeight: lineHeight,
      contentWidth: contentWidth,
      idealWidth: idealWidth,
    );
  }
}

/// نتيجة التحقق من صلاحية الشاشة
class ScreenValidation {
  final bool isValid;
  final bool isTooShort;
  final bool isTooTall;
  final bool isAspectDistorted;
  final bool isSmallScreen;
  final double lineHeight;
  final double contentWidth;
  final double idealWidth;
  
  const ScreenValidation({
    required this.isValid,
    required this.isTooShort,
    required this.isTooTall,
    required this.isAspectDistorted,
    required this.isSmallScreen,
    required this.lineHeight,
    required this.contentWidth,
    required this.idealWidth,
  });
  
  /// الحصول على رسالة تحذير إذا كانت الشاشة غير مثالية
  String? getWarningMessage() {
    if (isTooShort) {
      return 'الشاشة صغيرة جداً، تم تقليل حجم الأشرطة لمنع التداخل';
    }
    if (isAspectDistorted) {
      return 'نسبة الشاشة غير مثالية، قد يبدو النص مسطحاً';
    }
    return null;
  }
}
