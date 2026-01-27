
import 'package:flutter/material.dart';

class NavigationController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<int> mainTabNotifier = ValueNotifier<int>(0);
  
  static void switchTab(int index) {
    mainTabNotifier.value = index;
    // العودة للشاشة الرئيسية إذا كنا في شاشة فرعية
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
