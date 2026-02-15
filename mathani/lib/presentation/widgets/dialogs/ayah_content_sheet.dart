import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/surah_content_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/bookmark_provider.dart'; 
import '../../providers/quran_provider.dart'; // Added
import '../../providers/audio_provider.dart'; // Added for audio playback
import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_app/word_content.dart';

class AyahContentSheet extends StatefulWidget {
  final int surahNumber;
  final int ayaNumber;
  final int wordCount; // Hint for API to fetch range

  const AyahContentSheet({
    Key? key,
    required this.surahNumber,
    required this.ayaNumber,
    this.wordCount = 20, // Default fallback
  }) : super(key: key);

  @override
  State<AyahContentSheet> createState() => _AyahContentSheetState();
}

class _AyahContentSheetState extends State<AyahContentSheet> {
  String? _ayahText; // Store fetched ayah text

  @override
  void initState() {
    super.initState();
    // Initialize from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final defaultTafsir = context.read<SettingsProvider>().defaultTafsir;
      context.read<SurahContentProvider>().setTafsirSlug(defaultTafsir, shouldNotify: false);
      context.read<SurahContentProvider>().fetchContent(
        widget.surahNumber, 
        widget.ayaNumber, 
        widget.wordCount
      );
      
      // Fetch Ayah Text
      context.read<QuranProvider>().getAyahText(widget.surahNumber, widget.ayaNumber).then((text) {
        if (mounted) {
           setState(() {
             _ayahText = text;
           });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Slightly shorter for cleaner look
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Actions Bar (Replaces Header & Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Right Side: Tafsir Selector
                Expanded(
                  child: Consumer<SurahContentProvider>(
                    builder: (context, provider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.golden.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.golden.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedTafsirSlug,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'w-moyassar', child: Text('التفسير الميسر')),
                              DropdownMenuItem(value: 'tafsir-katheer', child: Text('تفسير ابن كثير')),
                              DropdownMenuItem(value: 'tafsir-saadi', child: Text('تفسير السعدي')),
                              DropdownMenuItem(value: 'tafsir-baghawy', child: Text('تفسير البغوي')),
                              DropdownMenuItem(value: 'tafsir-tabary', child: Text('تفسير الطبري')),
                              DropdownMenuItem(value: 'eerab-aya', child: Text('إعراب الآية')),
                              DropdownMenuItem(value: 'ayat-nozool', child: Text('أسباب النزول')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                provider.changeTafsir(val);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Left Side: Icons (Share, Audio, Bookmark)
                Row(
                  children: [
                    // Share
                    IconButton(
                      onPressed: () {
                         // TODO: Implement Share Logic (Text + Tafsir)
                      },
                      icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                      tooltip: 'مشاركة',
                    ),
                    
                    // Audio
                    Consumer<AudioProvider>(
                      builder: (context, audio, _) {
                        return IconButton(
                          onPressed: () {
                            // Start playing from this Ayah
                            audio.playAyah(widget.surahNumber, widget.ayaNumber);
                            Navigator.pop(context); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'بدأ التشغيل من الآية ${widget.ayaNumber}',
                                  style: const TextStyle(fontFamily: 'Tajawal'),
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                          tooltip: 'استماع',
                        );
                      },
                    ),
                    
                    // Bookmark
                    Consumer<BookmarkProvider>( 
                       builder: (context, bookmarks, _) {
                         final isBookmarked = bookmarks.isBookmarked(widget.surahNumber, widget.ayaNumber);
                         return IconButton(
                           onPressed: () {
                             if (isBookmarked) {
                               bookmarks.removeBookmark(widget.surahNumber, widget.ayaNumber);
                             } else {
                               bookmarks.addBookmark(widget.surahNumber, widget.ayaNumber);
                             }
                           },
                           icon: Icon(
                             isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                             color: AppColors.primary,
                           ),
                           tooltip: 'علامة مرجعية',
                         );
                       },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Consumer<SurahContentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final content = provider.currentAyaContent;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       // Ayah Text (Uthmanic)
                       if (_ayahText != null)
                         Container(
                           margin: const EdgeInsets.only(bottom: 24),
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: const Color(0xFFFFFDF5), // Light cream background
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: AppColors.golden.withValues(alpha: 0.2)),
                           ),
                           child: Text(
                             _ayahText!,
                             style: const TextStyle(
                               fontFamily: 'UthmanicHafs_V22', // The new font
                               fontSize: 24,
                               height: 1.6,
                               color: Colors.black,
                             ),
                             textAlign: TextAlign.center,
                             textDirection: TextDirection.rtl,
                           ),
                         ),
                         
                       content == null 
                        ? const Center(child: Text('لا يوجد محتوى متاح', style: TextStyle(fontFamily: 'Tajawal')))
                        : Text(
                            content.content,
                            style: const TextStyle(
                              fontFamily: 'Amiri', // Traditional font for Tafsir
                              fontSize: 18,
                              height: 1.8,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
