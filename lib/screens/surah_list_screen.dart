
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/database/collections.dart';
import '../providers/quran_provider.dart';
import 'mushaf_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({Key? key}) : super(key: key);

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  @override
  void initState() {
    super.initState();
    // Load data once when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurahs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'فهرس السور',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality to be implemented
            },
          ),
        ],
      ),
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.golden),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSurahs(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (provider.surahs.isEmpty) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85, // Adjusted for card height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.surahs.length,
            itemBuilder: (context, index) {
              final surah = provider.surahs[index];
              return _buildSurahCard(context, surah);
            },
          );
        },
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, Surah surah) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MushafScreen(surah: surah),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.golden.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Icon Faded
            Positioned(
              left: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.menu_book,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${surah.number}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        surah.revelation == RevelationType.meccan 
                            ? Icons.mosque // Use distinct icon if available, or color
                            : Icons.location_city,
                        size: 16,
                        color: AppColors.golden,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    surah.nameArabic,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    surah.nameEnglish,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${surah.numberOfAyahs} آية',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                      Text(
                        'جزء ${surah.juzNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
