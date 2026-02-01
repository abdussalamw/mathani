import 'package:flutter/material.dart';

/// وحدة تحكم التنقل العالمية
class NavigationController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// التنقل إلى صفحة جديدة
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// التنقل والاستبدال
  static Future<T?> navigateAndReplace<T>(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed<T, void>(routeName, arguments: arguments);
  }

  /// الرجوع للصفحة السابقة
  static void goBack<T>([T? result]) {
    navigator!.pop<T>(result);
  }

  /// مسح كل الصفحات والانتقال إلى صفحة جديدة
  static Future<T?> navigateAndRemoveUntil<T>(String routeName) {
    return navigator!.pushNamedAndRemoveUntil<T>(routeName, (_) => false);
  }
}
