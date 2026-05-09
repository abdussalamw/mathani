import 'package:flutter/material.dart';
import 'package:mathani/l10n/app_localizations.dart';
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
    // مزامنة الشريط السفلي عند السحب بين التبويبات
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final uiProvider = context.read<UiProvider>();
        if (uiProvider.indexScreenTabIndex != _tabController.index) {
          uiProvider.setTabIndex(0, indexScreenTab: _tabController.index);
        }
      }
    });
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
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: Column(
        children: [
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.brandGold,
                unselectedLabelColor: AppColors.mutedText,
                indicatorColor: AppColors.brandGold,
                indicatorWeight: 3,
                dividerColor: Colors.transparent, // Remove default divider
                labelStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15, // High density
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.surahs),
                  Tab(text: AppLocalizations.of(context)!.juz),
                  Tab(text: AppLocalizations.of(context)!.bookmarks),
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
