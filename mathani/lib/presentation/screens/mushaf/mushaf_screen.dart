import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'widgets/surah_header.dart';
import 'widgets/ayah_widget.dart';
import 'package:mathani/core/constants/app_colors.dart';

class MushafScreen extends StatefulWidget {
  final int initialSurah;
  
  const MushafScreen({
    Key? key,
    this.initialSurah = 1,
  }) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late QuranProvider _quranProvider;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _quranProvider = Provider.of<QuranProvider>(context, listen: false);
    _loadSurah();
  }
  
  Future<void> _loadSurah() async {
    // تحميل السورة المطلوبة
    await _quranProvider.loadSurah(widget.initialSurah);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5), // خلفية ورقية فاتحة
      appBar: AppBar(
        title: const Text(
          'المصحف الشريف',
          style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkBrown),
        titleTextStyle: const TextStyle(color: AppColors.darkBrown, fontSize: 22),
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }
          
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadSurah(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          if (provider.currentSurah == null || provider.currentAyahs.isEmpty) {
            return const Center(child: Text('لا توجد بيانات'));
          }
          
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // رأس السورة
              SliverToBoxAdapter(
                child: SurahHeader(
                  surah: provider.currentSurah!,
                ),
              ),
              
              // قائمة الآيات
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ayah = provider.currentAyahs[index];
                      return AyahWidget(
                        ayah: ayah,
                        onTap: () {
                          // عند النقر على آية - يمكن إضافة وظائف مثل الاستماع أو التفسير
                        },
                      );
                    },
                    childCount: provider.currentAyahs.length,
                  ),
                ),
              ),
              
              // مساحة إضافية في الأسفل للتنقل
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      // يمكن إضافة أزرار تنقل بين السور هنا
    );
  }
}
