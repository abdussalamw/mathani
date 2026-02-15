class TextUtils {
  static String normalizeQuranText(String text) {
    if (text.isEmpty) return '';
    
    String normalized = text;
    
    // 1. Remove Tashkeel & Quranic Marks
    normalized = normalized.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '');
    
    // 2. Normalize Alef
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    
    // 3. Normalize Yaa / Alif Maqsura
    normalized = normalized.replaceAll('ى', 'ي');
    
    // 4. Normalize Ta Marbuta
    normalized = normalized.replaceAll('ة', 'ه');
    
    // 5. Remove Tatweel (Kashida)
    normalized = normalized.replaceAll('ـ', '');
    
    // 6. Remove Waql (Pause marks) and exotic chars if any remaining
    // (The regex in step 1 covers most Quranic marks)

    return normalized;
  }
}
