import 'package:flutter/material.dart';

class FlutterFlowTheme {
  FlutterFlowTheme();

  static FlutterFlowTheme of(BuildContext context) => FlutterFlowTheme();

  // Colors عامة (من صور الثيم Light)
  Color get primary => const Color(0xFF182B54); // #182b54
  Color get secondary => const Color(0xFFE7DCCA); // #e7dcca
  Color get tertiary => const Color(0xFFF4EDE2); // #f4ede2

  Color get primaryBackground => const Color(0xFFF4EDE2); // #f4ede2
  Color get secondaryBackground => const Color(0xFFFDFBF6); // #fdfbf6

  Color get primaryText => const Color(0xFF0C162C); // #0c162c
  Color get secondaryText => const Color(0xFF36496C); // #36496c

  // أسماء مخصّصة تستخدمها صفحاتك (من Custom Colors في الصور)
  Color get subtextHints => const Color(0xFF36496C); // #36496c
  Color get backgroundElan => const Color(0xFFF4EDE2); // #f4ede2
  Color get containers => const Color(0xFFFDFBF6); // #fdfbf6

  // Main buttons / icons on light background
  Color get iconsOnLightBackgroundsMainButtonsOnLightBackgrounds =>
      const Color(0xFF182B54); // #182b54

  // أزرار/أيقونات
  Color get mainButtonsOnLight => primary;

  Color get secondaryButtonsOnLight => secondary;

  Color get iconsOnLight => primary;

  // Text styles مطلوبة
  TextStyle get displayLarge =>
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w800);

  TextStyle get titleLarge =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.w700);

  TextStyle get titleMedium =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  TextStyle get titleSmall =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  TextStyle get bodyLarge =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  TextStyle get bodyMedium =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  TextStyle get bodySmall =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

  TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get labelMedium =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  TextStyle get labelSmall =>
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  TextStyle get textHeadings =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  // مستخدم في الأخطاء: headlineSmall
  TextStyle get headlineSmall =>
      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  // ألوان ناقصة تستخدمها الصفحة
  Color get info =>
      const Color(0xFF4F6DB8); // #4f6db8 (Semantic Info من الصورة)
  Color get alternate =>
      const Color(0xFFFDFBF6); // #fdfbf6 (Alternate/Off-white)
  Color get secondaryButtonsOnLightBackgroundsNavigationBar => const Color(
    0xFFD5C1A6,
  ); // #d5c1a6 (Secondary buttons على الخلفية الفاتحة)
  Color get errorColor => const Color(0xFFB00020);

  Color get pagesBackground => primaryBackground;

  Color get error => const Color(0xFFB64B4B);

  Color get success => const Color(0xFF5B8A72);

  Color get warning => const Color(0xFFE1A948);

  // Styles ناقصة
  TextStyle get headlineLarge =>
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w600);
}
