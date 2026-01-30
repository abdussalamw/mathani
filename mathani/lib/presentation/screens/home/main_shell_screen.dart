
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../surah_list/surah_list_screen.dart';
import '../settings/settings_screen.dart';
import '../mushaf/mushaf_selection_screen.dart';
import '../mushaf/mushaf_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({Key? key}) : super(key: key);

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  // سيتم تخزين الصفحات هنا للحفاظ على حالتها
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const SurahListScreen(),       // 0: الفهرس
      const MushafSelectionScreen(), // 1: المصاحف
      const MushafScreen(),          // 2: القراءة (تلاوة)
      const SettingsScreen(),        // 3: الإعدادات
    ];
    

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal'),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_rounded),
              label: 'الفهرس',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'المصاحف',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'تلاوة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
