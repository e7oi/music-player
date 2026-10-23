// lib/theme/tuneshell_tokens.dart
//
// Jetons de design TuneShell (direction « Carapace sonore » v0.4).
// Source unique des couleurs, espacements, rayons, tailles et styles de texte.
// Requiert Flutter 3.27+ (rôles surfaceContainer* du ColorScheme, CardThemeData).
//
// Polices : embarquer Manrope et Inter (licence OFL) dans assets/fonts/
// et les déclarer dans pubspec.yaml sous les familles « Manrope » et « Inter ».
// Ne pas les télécharger à l'exécution (aucun appel réseau : promesse « sans télémétrie »).

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Espacements, rayons, tailles
// ─────────────────────────────────────────────────────────────

abstract final class TsSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Marge latérale des écrans.
  static const double screenMargin = 16;
}

abstract final class TsRadius {
  static const double xs = 4;
  static const double s = 8; // pochette 48
  static const double m = 12; // bandeaux, tuiles
  static const double l = 16; // cartes, mini-lecteur, grande pochette
  static const double xl = 28; // feuilles, bouton lecture plein écran
  static const double full = 999; // boutons, pastilles

  static const BorderRadius cover = BorderRadius.all(Radius.circular(s));
  static const BorderRadius banner = BorderRadius.all(Radius.circular(m));
  static const BorderRadius card = BorderRadius.all(Radius.circular(l));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class TsSize {
  static const double touchTarget = 48;
  static const double trackRow = 64;
  static const double coverSmall = 48;
  static const double coverPanel = 96;
  static const double coverPlayer = 348;
  static const double miniPlayer = 64;
  static const double navBar = 80;
  static const double navRail = 80;
  static const double playButton = 80;
  static const double playerPanelWidth = 280;
  static const double progressBar = 4;

  /// Points de rupture (largeur de fenêtre, en dp).
  static const double compactMax = 600;
  static const double expandedMin = 840;
}

abstract final class TsMotion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOutCubicEmphasized;
}

// ─────────────────────────────────────────────────────────────
// Couleurs
// ─────────────────────────────────────────────────────────────

abstract final class TsSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00695C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF9EF2E0),
    onPrimaryContainer: Color(0xFF00201B),
    secondary: Color(0xFF4A635F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCE8E2),
    onSecondaryContainer: Color(0xFF051F1C),
    tertiary: Color(0xFF7A5A1F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDEA6),
    onTertiaryContainer: Color(0xFF271900),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF5FAFA),
    onSurface: Color(0xFF171D1E),
    onSurfaceVariant: Color(0xFF3F4949),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF5F5),
    surfaceContainer: Color(0xFFE9EFEF),
    surfaceContainerHigh: Color(0xFFE3E9E9),
    surfaceContainerHighest: Color(0xFFDDE4E4),
    outline: Color(0xFF6F797A),
    outlineVariant: Color(0xFFBEC8C9),
    inverseSurface: Color(0xFF2B3132),
    onInverseSurface: Color(0xFFECF2F2),
    inversePrimary: Color(0xFF6FE3D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6FE3D0),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF005046),
    onPrimaryContainer: Color(0xFF8FF7E2),
    secondary: Color(0xFFB1CCC6),
    onSecondary: Color(0xFF1C3531),
    secondaryContainer: Color(0xFF24464A),
    onSecondaryContainer: Color(0xFFCCE8E2),
    tertiary: Color(0xFFF2BF6B),
    onTertiary: Color(0xFF3F2D00),
    tertiaryContainer: Color(0xFF5C4300),
    onTertiaryContainer: Color(0xFFFFDEA6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F1522),
    onSurface: Color(0xFFDEE3EA),
    onSurfaceVariant: Color(0xFFBCC6D2),
    surfaceContainerLowest: Color(0xFF0A0F19),
    surfaceContainerLow: Color(0xFF161D2A),
    surfaceContainer: Color(0xFF1B2230),
    surfaceContainerHigh: Color(0xFF252D3A),
    surfaceContainerHighest: Color(0xFF2F3745),
    outline: Color(0xFF8A94A2),
    outlineVariant: Color(0xFF3B4555),
    inverseSurface: Color(0xFFDEE3EA),
    onInverseSurface: Color(0xFF2B313D),
    inversePrimary: Color(0xFF00695C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

/// Couleurs propres à TuneShell, absentes du ColorScheme Material.
/// Restent fixes même si les couleurs dynamiques (fond d'écran) sont activées.
@immutable
class TsColors extends ThemeExtension<TsColors> {
  const TsColors({
    required this.unavailable,
    required this.nowPlayingRow,
    required this.coverPlaceholder,
    required this.brandMint,
    required this.brandCyan,
    required this.brandNight,
  });

  /// Texte et icône des pistes d'un disque absent (contraste ≥ 4,6:1).
  final Color unavailable;

  /// Fond de la ligne en cours de lecture.
  final Color nowPlayingRow;

  /// Tuile affichée quand une piste n'a pas de pochette.
  final Color coverPlaceholder;

  /// Couleurs de marque : logo, démarrage. Jamais derrière du texte.
  final Color brandMint;
  final Color brandCyan;
  final Color brandNight;

  static const TsColors light = TsColors(
    unavailable: Color(0xFF6A7475),
    nowPlayingRow: Color(0xFFDDF3EE),
    coverPlaceholder: Color(0xFFE3E9E9),
    brandMint: Color(0xFF74FDD3),
    brandCyan: Color(0xFF3DD6D9),
    brandNight: Color(0xFF0D1528),
  );

  static const TsColors dark = TsColors(
    unavailable: Color(0xFF8A94A2),
    nowPlayingRow: Color(0xFF123036),
    coverPlaceholder: Color(0xFF252D3A),
    brandMint: Color(0xFF74FDD3),
    brandCyan: Color(0xFF3DD6D9),
    brandNight: Color(0xFF0D1528),
  );

  /// Raccourci : `TsColors.of(context).unavailable`.
  static TsColors of(BuildContext context) =>
      Theme.of(context).extension<TsColors>()!;

  @override
  TsColors copyWith({
    Color? unavailable,
    Color? nowPlayingRow,
    Color? coverPlaceholder,
    Color? brandMint,
    Color? brandCyan,
    Color? brandNight,
  }) {
    return TsColors(
      unavailable: unavailable ?? this.unavailable,
      nowPlayingRow: nowPlayingRow ?? this.nowPlayingRow,
      coverPlaceholder: coverPlaceholder ?? this.coverPlaceholder,
      brandMint: brandMint ?? this.brandMint,
      brandCyan: brandCyan ?? this.brandCyan,
      brandNight: brandNight ?? this.brandNight,
    );
  }

  @override
  TsColors lerp(ThemeExtension<TsColors>? other, double t) {
    if (other is! TsColors) return this;
    return TsColors(
      unavailable: Color.lerp(unavailable, other.unavailable, t)!,
      nowPlayingRow: Color.lerp(nowPlayingRow, other.nowPlayingRow, t)!,
      coverPlaceholder:
          Color.lerp(coverPlaceholder, other.coverPlaceholder, t)!,
      brandMint: Color.lerp(brandMint, other.brandMint, t)!,
      brandCyan: Color.lerp(brandCyan, other.brandCyan, t)!,
      brandNight: Color.lerp(brandNight, other.brandNight, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Typographie
// ─────────────────────────────────────────────────────────────

abstract final class TsFonts {
  static const String display = 'Manrope';
  static const String text = 'Inter';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

abstract final class TsText {
  static const TextTheme theme = TextTheme(
    displaySmall: TextStyle(
        fontFamily: TsFonts.display, fontWeight: FontWeight.w800,
        fontSize: 36, height: 44 / 36, letterSpacing: -0.72),
    headlineSmall: TextStyle(
        fontFamily: TsFonts.display, fontWeight: FontWeight.w800,
        fontSize: 28, height: 36 / 28, letterSpacing: -0.28),
    titleLarge: TextStyle(
        fontFamily: TsFonts.display, fontWeight: FontWeight.w700,
        fontSize: 22, height: 28 / 22),
    titleMedium: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w500,
        fontSize: 16, height: 24 / 16),
    titleSmall: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w600,
        fontSize: 14, height: 20 / 14),
    bodyLarge: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w400,
        fontSize: 16, height: 24 / 16),
    bodyMedium: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w400,
        fontSize: 14, height: 20 / 14),
    bodySmall: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w400,
        fontSize: 12, height: 16 / 12),
    labelLarge: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w600,
        fontSize: 14, height: 20 / 14),
    labelMedium: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w500,
        fontSize: 12, height: 16 / 12, fontFeatures: TsFonts.tabular),
    labelSmall: TextStyle(
        fontFamily: TsFonts.text, fontWeight: FontWeight.w600,
        fontSize: 11, height: 16 / 11, letterSpacing: 0.44),
  );

  /// Titre du lecteur plein écran.
  static const TextStyle playerTitle = TextStyle(
      fontFamily: TsFonts.display, fontWeight: FontWeight.w800,
      fontSize: 24, height: 32 / 24);
}

// ─────────────────────────────────────────────────────────────
// Thèmes
// ─────────────────────────────────────────────────────────────

abstract final class TsTheme {
  static ThemeData light({ColorScheme? dynamicScheme}) =>
      _build(dynamicScheme ?? TsSchemes.light, TsColors.light);

  static ThemeData dark({ColorScheme? dynamicScheme}) =>
      _build(dynamicScheme ?? TsSchemes.dark, TsColors.dark);

  static ThemeData _build(ColorScheme scheme, TsColors ts) {
    final text = TsText.theme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [ts],
      navigationBarTheme: NavigationBarThemeData(
        height: TsSize.navBar,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        minWidth: TsSize.navRail,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: TsRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: TsSize.progressBar,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: TsRadius.sheet),
        showDragHandle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, TsSize.touchTarget),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, TsSize.touchTarget),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, TsSize.touchTarget),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(TsSize.touchTarget),
        ),
      ),
    );
  }
}

// Utilisation :
//
// MaterialApp(
//   theme: TsTheme.light(),
//   darkTheme: TsTheme.dark(),
//   themeMode: ThemeMode.system,
// );
//
// Couleurs dynamiques (option « Couleurs du fond d'écran », paquet dynamic_color) :
//   DynamicColorBuilder(builder: (lightDyn, darkDyn) => MaterialApp(
//     theme: TsTheme.light(dynamicScheme: useDynamic ? lightDyn : null),
//     darkTheme: TsTheme.dark(dynamicScheme: useDynamic ? darkDyn : null),
//   ));
