import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

class AyahWidget extends StatelessWidget {
  final int number;
  final String text;

  const AyahWidget({
    Key? key,
    required this.number,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.quranText,
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' \uFD3F${number.toString()}\uFD3E ', // نهاية الآية
            style: const TextStyle(
              fontFamily: 'HafsSmart',
              color: Color(0xFFD4AF37), // ذهبي
              fontSize: 18,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
