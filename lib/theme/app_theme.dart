import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/strings.dart';

/// Colors used across the app (matches the design canvas).
class AppColors {
  static const ground = Color(0xFFF4F2EC); // page background
  static const surface = Color(0xFFFFFFFF); // cards
  static const ink = Color(0xFF17201C); // main text
  static const body = Color(0xFF2E3833); // long-form text
  static const muted = Color(0xFF5B655F); // secondary text
  static const line = Color(0xFFE2DED3); // borders
  static const divider = Color(0xFFEEEBE3);
  static const green = Color(0xFF1E4A3D); // primary
  static const greenSoft = Color(0xFFE3EBE6);
  static const gold = Color(0xFF9A6B1F); // accent (text-safe)
  static const goldDark = Color(0xFF6E4B12);
  static const sand = Color(0xFFE8D9B5); // accent on green
  static const sandSoft = Color(0xFFF3EAD6);
  static const segment = Color(0xFFE9E5DA);
  static const switchOff = Color(0xFFC9C4B7);
  static const onGreenMuted = Color(0xFFC9D6D0);
  static const onGreenBody = Color(0xFFE4ECE8);
  // Prayer card (night blue with gold)
  static const night = Color(0xFF1F3A5F);
  static const nightGold = Color(0xFFF2C14E);
  static const onNightMuted = Color(0xFFC3CFE0);
  static const onNightBody = Color(0xFFE6ECF5);
}

/// Text helpers.
/// Interface text: IBM Plex Sans Arabic for Arabic/Urdu, Figtree for English.
/// Hadith and dhikr text: Amiri.
class AppText {
  static TextStyle ui({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    FontStyle? style,
  }) {
    if (S.isRtl) {
      // Letter spacing breaks Arabic letter joining, so it is always 0 here.
      return GoogleFonts.ibmPlexSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: 0,
        fontStyle: style,
      );
    }
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
    );
  }

  static TextStyle arabic({
    double size = 26,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double height = 1.8,
  }) =>
      GoogleFonts.amiri(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle title() =>
      ui(size: 26, weight: FontWeight.w700, letterSpacing: -0.3);

  static TextStyle overline({Color color = AppColors.muted}) =>
      ui(size: 12, weight: FontWeight.w700, letterSpacing: 1.2, color: color);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        surface: AppColors.ground,
      ),
      scaffoldBackgroundColor: AppColors.ground,
    );
    final textTheme = S.isRtl
        ? GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
        : GoogleFonts.figtreeTextTheme(base.textTheme);
    return base.copyWith(
      textTheme:
          textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.greenSoft,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText.ui(
            size: 11,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.green : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.green : AppColors.muted,
            size: 24,
          );
        }),
      ),
    );
  }
}
