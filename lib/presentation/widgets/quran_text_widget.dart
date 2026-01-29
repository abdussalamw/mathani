import 'package:flutter/material.dart';
import 'package:mathani/core/services/quran_font_loader.dart';
import 'package:mathani/core/constants/app_colors.dart';

class QuranTextWidget extends StatefulWidget {
  final String text;
  final int pageNumber;
  final double fontSize;
  final Color? textColor;
  final TextAlign textAlign;
  final double lineHeight;
  final bool useQCF2; // استخدام QCF2 أو الخط الاحتياطي
  
  const QuranTextWidget({
    Key? key,
    required this.text,
    required this.pageNumber,
    this.fontSize = 28,
    this.textColor,
    this.textAlign = TextAlign.justify,
    this.lineHeight = 2.2,
    this.useQCF2 = true,
  }) : super(key: key);

  @override
  State<QuranTextWidget> createState() => _QuranTextWidgetState();
}

class _QuranTextWidgetState extends State<QuranTextWidget> {
  String? _fontFamily;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.useQCF2) {
      _loadFont();
    } else {
      setState(() {
        _fontFamily = 'Amiri'; // خط احتياطي
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadFont() async {
    final fontLoader = QuranFontLoader.instance;
    final fontFamily = await fontLoader.loadFontForPage(widget.pageNumber);
    
    if (mounted) {
      setState(() {
        _fontFamily = fontFamily ?? 'Amiri'; // احتياطي
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.fontSize * widget.lineHeight,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }
    
    return Text(
      widget.text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: widget.fontSize,
        color: widget.textColor ?? AppColors.darkBrown,
        height: widget.lineHeight,
        letterSpacing: 0.5,
      ),
      textAlign: widget.textAlign,
      textDirection: TextDirection.rtl,
    );
  }
}
