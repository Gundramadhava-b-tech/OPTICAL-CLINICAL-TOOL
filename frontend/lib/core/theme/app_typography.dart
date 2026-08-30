import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography Manager for RetinaSeg AI
/// Automatically adapts font family, weights, and line heights according to active Locale.
class AppTypography {
  /// Supported Unicode Fallback Font Families
  static const List<String> fontFallbacks = [
    'Inter',
    'Roboto',
    'Noto Sans',
    'Noto Sans Telugu',
    'Noto Sans Devanagari',
    'Noto Sans Tamil',
    'sans-serif',
  ];

  /// Returns the human-readable font family name for a given locale
  static String getFontFamilyName(Locale locale) {
    switch (locale.languageCode) {
      case 'te':
        return 'Noto Sans Telugu';
      case 'hi':
        return 'Noto Sans Devanagari';
      case 'ta':
        return 'Noto Sans Tamil';
      case 'en':
      default:
        return 'Inter';
    }
  }

  /// Returns the localized font sample preview text for Settings
  static String getFontPreviewText(Locale locale) {
    switch (locale.languageCode) {
      case 'te':
        return 'ఆటోమేటెడ్ రెటీనా పొరల విభజన';
      case 'hi':
        return 'स्वचालित रेटिना परत विभाजन';
      case 'ta':
        return 'தானியங்கி விழித்திரை அடுக்கு பிரிப்பு';
      case 'en':
      default:
        return 'Automated Retinal Layer Segmentation';
    }
  }

  /// Builds a complete Material 3 TextTheme tailored to the active language and colors
  static TextTheme buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
    required Locale locale,
  }) {
    final lang = locale.languageCode;
    TextTheme base;
    final double lineHeight = (lang == 'te' || lang == 'hi' || lang == 'ta') ? 1.38 : 1.25;

    switch (lang) {
      case 'te':
        base = GoogleFonts.notoSansTeluguTextTheme();
        break;
      case 'hi':
        base = GoogleFonts.notoSansDevanagariTextTheme();
        break;
      case 'ta':
        base = GoogleFonts.notoSansTamilTextTheme();
        break;
      case 'en':
      default:
        base = GoogleFonts.interTextTheme();
        break;
    }

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        height: lineHeight,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        height: lineHeight,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: lineHeight,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: lineHeight,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: lineHeight,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        height: lineHeight,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        height: lineHeight,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: mutedColor,
        height: lineHeight,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: lineHeight,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: lineHeight,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        height: lineHeight,
      ),
    );
  }
}
