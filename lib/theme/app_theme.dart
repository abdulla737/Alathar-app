import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/strings.dart';

/// A color with a light and a dark value. Which one it shows is read from
/// [AppColors.isDark] each time it is used, so the app's existing `const`
/// widgets keep working. The app rebuilds its whole tree when the mode
/// changes (see main.dart).
class _Adaptive extends Color {
  const _Adaptive(super.light, this.darkColor);
  final Color darkColor;

  @override
  double get a => AppColors.isDark ? darkColor.a : super.a;
  @override
  double get r => AppColors.isDark ? darkColor.r : super.r;
  @override
  double get g => AppColors.isDark ? darkColor.g : super.g;
  @override
  double get b => AppColors.isDark ? darkColor.b : super.b;
  // value / toARGB32 / withValues / == are all computed from a, r, g, b.
}

/// Colors used across the app (matches the design canvas). Each has a light
/// and a dark value; the prayer card's night blue and gold stay the same.
class AppColors {
  /// Dark mode, set from [AppSettings] (toggle on the Today page).
  static bool isDark = false;

  static const ground = _Adaptive(0xFFF4F2EC, Color(0xFF111614)); // page background
  static const surface = _Adaptive(0xFFFFFFFF, Color(0xFF1B2220)); // cards
  static const ink = _Adaptive(0xFF17201C, Color(0xFFE9EEEB)); // main text
  static const body = _Adaptive(0xFF2E3833, Color(0xFFD2DAD5)); // long-form text
  static const muted = _Adaptive(0xFF5B655F, Color(0xFF9BA7A0)); // secondary text
  static const line = _Adaptive(0xFFE2DED3, Color(0xFF2C3632)); // borders
  static const divider = _Adaptive(0xFFEEEBE3, Color(0xFF242C29));
  static const green = _Adaptive(0xFF1E4A3D, Color(0xFF357A62)); // primary
  static const greenSoft = _Adaptive(0xFFE3EBE6, Color(0xFF22352D));
  static const gold = _Adaptive(0xFF9A6B1F, Color(0xFFD7A65A)); // accent (text-safe)
  static const goldDark = _Adaptive(0xFF6E4B12, Color(0xFFE6C27E));
  static const brown = _Adaptive(0xFF3D2A08, Color(0xFFF0DDB0)); // text on sandSoft
  static const sand = Color(0xFFE8D9B5); // accent on green
  static const sandSoft = _Adaptive(0xFFF3EAD6, Color(0xFF3A3324));
  static const segment = _Adaptive(0xFFE9E5DA, Color(0xFF252E2A));
  static const switchOff = _Adaptive(0xFFC9C4B7, Color(0xFF4B5550));
  static const onGreenMuted = Color(0xFFC9D6D0);
  static const onGreenBody = Color(0xFFE4ECE8);
  // Prayer card (night blue with gold)
  static const night = Color(0xFF1F3A5F);
  static const nightGold = Color(0xFFF2C14E);
  static const onNightMuted = Color(0xFFC3CFE0);
  static const onNightBody = Color(0xFFE6ECF5);
}

/// Tajweed colors, as in the Dar al-Maarifah colour-coded mushaf. Each has
/// a lighter tone for dark mode.
class TajweedColors {
  /// Madd lazim, 6 counts: dark red.
  static const madd6 = _Adaptive(0xFFB00010, Color(0xFFFF6B6B));
  /// Madd wajib (muttasil), 4–5 counts: red.
  static const maddWajib = _Adaptive(0xFFE8263A, Color(0xFFFF8A8A));
  /// Madd ja'iz (munfasil, ʿarid, leen), 2–4–6 counts: orange.
  static const maddJaiz = _Adaptive(0xFFEF7D00, Color(0xFFFFB04D));
  /// Natural madd, 2 counts: gold.
  static const madd2 = _Adaptive(0xFFB98B00, Color(0xFFE3C15A));
  /// Ghunnah, ikhfa, iqlab, idgham with ghunnah: green.
  static const ghunnah = _Adaptive(0xFF16943A, Color(0xFF5FD27A));
  /// Qalqalah: blue.
  static const qalqalah = _Adaptive(0xFF1E7FD8, Color(0xFF6CB8FF));
  /// Not pronounced (hamzat al-wasl, lam shamsiyyah, silent letters,
  /// idgham without ghunnah): grey.
  static const silent = _Adaptive(0xFF9A9A9A, Color(0xFF7C8580));

  /// Color for a rule name from the tajweed data.
  static Color? of(String rule) => switch (rule) {
        'madd_6' => madd6,
        'madd_muttasil' => maddWajib,
        'madd_munfasil' || 'madd_246' => maddJaiz,
        'madd_2' => madd2,
        'ghunnah' || 'ikhfa' || 'ikhfa_shafawi' || 'iqlab' || 'idghaam_ghunnah' ||
        'idghaam_shafawi' =>
          ghunnah,
        'qalqalah' => qalqalah,
        'hamzat_wasl' || 'lam_shamsiyyah' || 'silent' || 'idghaam_no_ghunnah' ||
        'idghaam_mutajanisayn' || 'idghaam_mutaqaribayn' =>
          silent,
        _ => null,
      };

  /// When rules overlap, the stronger one shows (madd over the rest).
  static int priority(String rule) => switch (rule) {
        'madd_6' => 9,
        'madd_muttasil' => 8,
        'madd_munfasil' || 'madd_246' => 7,
        'madd_2' => 6,
        'qalqalah' => 5,
        'ghunnah' || 'ikhfa' || 'ikhfa_shafawi' || 'iqlab' || 'idghaam_ghunnah' ||
        'idghaam_shafawi' =>
          4,
        _ => 1,
      };
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
  /// The theme for the current mode ([AppColors.isDark]).
  static ThemeData light() {
    final dark = AppColors.isDark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E4A3D),
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: Color(AppColors.green.toARGB32()),
        surface: Color(AppColors.ground.toARGB32()),
      ),
      scaffoldBackgroundColor: AppColors.ground,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
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
