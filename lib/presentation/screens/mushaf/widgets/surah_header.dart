import 'package:flutter/material.dart';

class SurahHeader extends StatelessWidget {
  final String title;

  const SurahHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/decorations/surah_header_bg.png'),
          fit: BoxFit.contain,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black, // أو حسب التصميم
          ),
        ),
      ),
    );
  }
}
