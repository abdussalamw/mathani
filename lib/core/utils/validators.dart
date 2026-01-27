class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'مطلوب';
    if (!value.contains('@')) return 'بريد إلكتروني غير صحيح';
    return null;
  }
}
