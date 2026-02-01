import 'package:flutter/material.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/tafsir_provider.dart';
import 'package:provider/provider.dart';

class TafsirScreen extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const TafsirScreen({
    Key? key,
    this.surahNumber = 1,
    this.ayahNumber = 1,
  }) : super(key: key);

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  late int _currentAyahNumber;
  late int _currentSurahNumber;
  final String _currentTafsirSource = 'الميسر';

  @override
  void initState() {
    super.initState();
    _currentAyahNumber = widget.ayahNumber;
    _currentSurahNumber = widget.surahNumber;
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurah(_currentSurahNumber);
      context.read<TafsirProvider>().fetchTafsir(_currentSurahNumber, _currentAyahNumber);
    });
  }

  void _onAyahChanged(int newAyah) {
    setState(() => _currentAyahNumber = newAyah);
    context.read<TafsirProvider>().fetchTafsir(_currentSurahNumber, _currentAyahNumber);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'التفسير',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   // Ayah Box
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: isDark ? const Color(0xFF2C2416) : Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.golden.withValues(alpha: 0.1),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                       border: Border.all(
                         color: AppColors.golden.withValues(alpha: 0.3),
                         width: 1,
                       ),
                     ),
                     child: Column(
                       children: [
                         Text(
                           'سورة $_currentSurahNumber - آية $_currentAyahNumber',
                           style: const TextStyle(
                             fontFamily: 'Tajawal',
                             fontSize: 14,
                             color: AppColors.golden,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         const SizedBox(height: 16),
                         Consumer<QuranProvider>(
                           builder: (context, quran, _) {
                             String txt = '...';
                             if (quran.isLoading) {
                               txt = 'جاري التحميل...';
                             } else if (quran.currentAyahs.isNotEmpty) {
                               try {
                                 final ayah = quran.currentAyahs.firstWhere(
                                   (a) => a.ayahNumber == _currentAyahNumber);
                                 txt = ayah.text;
                               } catch (_) {
                                 txt = quran.currentAyahs.first.text;
                               }
                             }
                             
                             return Text(
                               txt,
                               textAlign: TextAlign.center,
                               textDirection: TextDirection.rtl,
                               style: TextStyle(
                                 fontFamily: 'Amiri',
                                 fontSize: 26,
                                 height: 1.8,
                                 color: isDark ? Colors.white : Colors.black87,
                                 fontWeight: FontWeight.bold,
                               ),
                             );
                           },
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Tafsir Source Indicator
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(30),
                     ),
                     child: Text(
                       'التفسير: $_currentTafsirSource',
                       style: TextStyle(
                         fontFamily: 'Tajawal',
                         fontSize: 12,
                         color: Colors.grey[600],
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                    // Tafsir Text
                    Consumer<TafsirProvider>(
                      builder: (context, tafsir, _) {
                        if (tafsir.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(color: AppColors.golden),
                            ),
                          );
                        }
                        
                        if (tafsir.errorMessage != null) {
                          return Center(
                            child: Text(
                              tafsir.errorMessage!,
                              style: const TextStyle(fontFamily: 'Tajawal', color: Colors.red),
                            ),
                          );
                        }

                        return Text(
                          tafsir.tafsirContent,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            height: 1.6,
                            color: isDark ? Colors.grey[300] : const Color(0xFF4A4A4A),
                          ),
                        );
                      },
                    ),
                 ],
               ),
             ),
           ),
           
           // Bottom Controls
           Container(
             padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
             decoration: BoxDecoration(
               color: isDark ? const Color(0xFF231E18) : Colors.white,
               boxShadow: [
                 BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
               ],
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 // Previous Ayah
                 ElevatedButton(
                   onPressed: _currentAyahNumber < 286 // Simple cap for demo, better check surah total
                     ? () => _onAyahChanged(_currentAyahNumber + 1)
                     : null,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: const CircleBorder(),
                     padding: const EdgeInsets.all(12),
                   ),
                   child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                 ),
                 
                  // Tafsir Selection Button
                  OutlinedButton.icon(
                     onPressed: () {
                       // Show Bottom Sheet to select Tafsir
                     },
                     icon: const Icon(Icons.menu_book),
                     label: const Text('تغيير التفسير'),
                     style: OutlinedButton.styleFrom(
                       foregroundColor: AppColors.golden,
                       side: const BorderSide(color: AppColors.golden),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     ),
                  ),
                  
                  // Next Ayah
                  ElevatedButton(
                   onPressed: _currentAyahNumber > 1
                     ? () => _onAyahChanged(_currentAyahNumber - 1)
                     : null,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: const CircleBorder(),
                     padding: const EdgeInsets.all(12),
                   ),
                   child: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}
