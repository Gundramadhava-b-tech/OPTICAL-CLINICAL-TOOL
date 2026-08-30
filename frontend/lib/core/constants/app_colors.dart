import 'package:flutter/material.dart';

class AppColors {
  // Primary Clinical Palette
  static const Color primary = Color(0xFF006699);
  static const Color primaryDark = Color(0xFF004B73);
  static const Color primaryLight = Color(0xFFE1EFF7);
  static const Color primarySurface = Color(0xFFF0F7FB);
  
  // Secondary Teal / Accent Palette
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFFE0F2F1);
  static const Color secondaryDark = Color(0xFF005B4F);

  // Background & Surfaces
  static const Color background = Color(0xFFF4F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDF2F7);
  static const Color cardBorder = Color(0xFFD2E3EF);
  static const Color divider = Color(0xFFE2E8F0);

  // Clinical Typography / Neutral Colors
  static const Color textPrimary = Color(0xFF0F2438);
  static const Color textSecondary = Color(0xFF55697D);
  static const Color textMuted = Color(0xFF8899A8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status & Severity Colors
  static const Color success = Color(0xFF0D9488);
  static const Color successLight = Color(0xFFCCFBF1);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Retinal Layer Segmentation Overlay Palette (8 Distinct Anatomical Layers)
  static const Color layerILM = Color(0xFFFF3366);      // Pink/Red: Inner Limiting Membrane
  static const Color layerRNFL = Color(0xFFFF6600);     // Orange: Retinal Nerve Fiber Layer
  static const Color layerGCL = Color(0xFFFFCC00);      // Yellow-Amber: Ganglion Cell Layer
  static const Color layerIPL = Color(0xFF00CC66);      // Green: Inner Plexiform Layer
  static const Color layerINL = Color(0xFF0099FF);      // Cyan-Blue: Inner Nuclear Layer
  static const Color layerOPL = Color(0xFF3366FF);      // Blue: Outer Plexiform Layer
  static const Color layerONL = Color(0xFF9933FF);      // Purple: Outer Nuclear Layer / IS
  static const Color layerRPE = Color(0xFFFF0080);      // Magenta: Retinal Pigment Epithelium / OS
  
  static Color getLayerColor(String layerName) {
    switch (layerName.toUpperCase()) {
      case 'ILM': return layerILM;
      case 'RNFL': return layerRNFL;
      case 'GCL': return layerGCL;
      case 'IPL': return layerIPL;
      case 'INL': return layerINL;
      case 'OPL': return layerOPL;
      case 'ONL': return layerONL;
      case 'RPE': return layerRPE;
      default: return const Color(0xFF00B4D8);
    }
  }
}
