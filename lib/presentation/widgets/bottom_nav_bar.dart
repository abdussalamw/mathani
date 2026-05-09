import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: 'الفهرس',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_rounded),
          label: 'المصاحف',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_rounded),
          label: 'المصحف',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: 'الإعدادات',
        ),
      ],
    );
  }
}
