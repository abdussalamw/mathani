import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF8F8F8),
      child: Consumer<AudioProvider>(
        builder: (context, audio, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Reciter Image / Art
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2416) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    // image: DecorationImage(...) // Future: Add reciter image
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: 100,
                      color: AppColors.golden.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Info
                Text(
                  audio.currentSurah != null ? 'سورة ${audio.currentSurah}' : 'اختر تلاوة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  audio.currentReciter['name'] ?? 'قارئ غير معروف',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Seek Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: AppColors.golden,
                        inactiveTrackColor: AppColors.golden.withValues(alpha: 0.2),
                        thumbColor: AppColors.golden,
                        overlayColor: AppColors.golden.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: 0.3, // Mock Progress
                        onChanged: (val) {},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('00:45', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey[500])),
                          Text('01:30', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle, size: 24),
                      color: Colors.grey,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 24),
                    
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 36),
                      color: isDark ? Colors.white : Colors.black87,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 24),
                    
                    // Play/Pause Button
                    GestureDetector(
                      onTap: () {
                        if (audio.isPlaying) {
                          audio.pause();
                        } else {
                          audio.play();
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 36),
                      color: isDark ? Colors.white : Colors.black87,
                      onPressed: () {},
                    ),
                    
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.repeat, size: 24),
                      color: Colors.grey,
                      onPressed: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Selectors Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.format_list_bulleted),
                        label: const Text('قائمة السور'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: AppColors.grey10),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          // Open Surah Selector
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('اختر القارئ'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: AppColors.grey10),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          _showReciterSelector(context, audio);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReciterSelector(BuildContext context, AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'اختر القارئ',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: audio.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = audio.reciters[index];
                    final isSelected = audio.currentReciter['id'] == reciter['id'];
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(
                        reciter['name']!,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                      onTap: () {
                        audio.setReciter(reciter);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
