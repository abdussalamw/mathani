import 'package:flutter/material.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/screens/surah_list/surah_list_screen.dart';
import 'package:mathani/presentation/screens/bookmarks/bookmarks_screen.dart';
import 'package:mathani/presentation/screens/index/widgets/juz_tab_view.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:provider/provider.dart';

/// الشاشة الرئيسية للفهرس مع 3 تبويبات
class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final uiProvider = context.read<UiProvider>();
    _lastTabIndex = uiProvider.indexScreenTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: _lastTabIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uiProvider = context.watch<UiProvider>();
    final newTabIndex = uiProvider.indexScreenTabIndex.clamp(0, 2);
    
    // Update tab if it changed
    if (newTabIndex != _lastTabIndex && _tabController.index != newTabIndex) {
      _lastTabIndex = newTabIndex;
      _tabController.animateTo(newTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      child: Column(
        children: [
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2416) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.golden,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'السور'),
                  Tab(text: 'الأجزاء'),
                  Tab(text: 'العلامات'),
                ],
              ),
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SurahListScreen(),
                JuzTabView(),
                BookmarksScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
