// Design tokens of TuneShell (direction "Carapace sonore" v0.4): the single
// source of colours, spacing, radii, sizes and text styles (FR-008, ADR-010).
// Values come from the Claude Design handoff (docs/design/HANDOFF.md); if two
// sources disagree, this file wins over the mock-ups.
//
// Fonts: Manrope and Inter are bundled in assets/fonts (OFL licence) and
// declared in pubspec.yaml. They are never downloaded at run time (BR-007).

import 'package:flutter/material.dart';

// Spacing, radii, sizes

abstract final class TsSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Side margin of the screens.
  static const double screenMargin = 16;
}

abstract final class TsRadius {
  static const double xs = 4;
  static const double s = 8; // 48 dp cover
  static const double m = 12; // banners, tiles
  static const double l = 16; // cards, mini player, large cover
  static const double xl = 28; // sheets, full-screen play button
  static const double full = 999; // buttons, chips

  static const BorderRadius cover = BorderRadius.all(Radius.circular(s));
  static const BorderRadius banner = BorderRadius.all(Radius.circular(m));
  static const BorderRadius card = BorderRadius.all(Radius.circular(l));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

abstract final class TsSize {
  static const double touchTarget = 48;
  static const double trackRow = 64;
  static const double coverSmall = 48;
  static const double coverPanel = 96;
  static const double coverDetail = 152; // album and artist detail header
  static const double coverPlayer = 348;
  static const double miniPlayer = 64;
  static const double navBar = 80;
  static const double navRail = 80;
  static const double playButton = 80;
  static const double playerPanelWidth = 280;
  static const double progressBar = 4;
  static const double miniProgress = 2; // thin bar under the mini player
  static const double sourceMarkMini = 10; // source mark in the mini player
  static const double toggleDot = 4; // active dot under shuffle and repeat
  static const double sheetHandle = 4; // grabber of a bottom sheet
  static const double sheetHandleWidth = 32;
  static const double closeFlingVelocity =
      700; // swipe down to close the player
  static const double transportIcon = 32; // previous, play and next
  static const double albumCardMinWidth = 160; // grid of albums
  static const double albumCardTextHeight =
      56; // title and subtitle below a cover
  static const double albumTrackRow = 56; // track of an album detail
  static const double letterHeader = 40; // letter of the artists list
  static const int albumColumnsMax = 6;
  static const double carouselCard = 120; // album card of an artist detail
  static const double queueSheetInitial = 0.6; // share of the screen
  static const double queueSheetMin = 0.3;
  static const double bannerMin = 56; // status banner
  static const double fixedRowMaxTextScale = 1.3; // above: rows grow
  static const double sourceMark = 12; // source mark on a TrackTile
  static const double fab = 56; // "jump to current" button
  static const double buttonLarge = 56; // primary button of a full screen
  static const double heroTile = 144; // icon tile of the access screens
  static const double heroIcon = 72;
  static const double logo = 120; // logo of the welcome screen
  static const double stepDot = 8; // step indicator
  static const double stepDotActive = 24;
  static const double listBottomInset =
      88; // room under a list so the jump button never hides the last row

  // Alphabet index (AlphabetScroller)
  static const double indexHandleWidth = 6; // handle visible at rest
  static const double indexHandleHeight = 48;
  static const Size indexHandleTouch = Size(32, 64); // touch area of the handle
  static const double indexColumnWidth = 32;
  static const double indexEdgeInset = 4; // gap to the screen edge
  static const double indexLetterBase = 11; // letter size at rest
  static const double indexLetterMax = 26; // letter under the finger
  static const double indexShiftMax =
      34; // inward shift of the letter under the finger
  static const int indexInfluence = 2; // neighbours enlarged on each side
  static const double indexBubble = 72; // bubble of the current letter
  static const double indexGestureExclusionMax = 200; // Android limit per edge

  /// Breakpoints (window width, in dp).
  static const double compactMax = 600;
  static const double expandedMin = 840;
}

abstract final class TsMotion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOutCubicEmphasized;

  // Alphabet index
  static const Duration indexShow = Duration(milliseconds: 150);
  static const Duration indexHideDelay = Duration(milliseconds: 600);
  static const Duration handleIdleHide = Duration(milliseconds: 1500);
}

// Colours

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

/// TuneShell colours missing from the Material ColorScheme. They stay fixed
/// even when dynamic (wallpaper) colours are on.
@immutable
class TsColors extends ThemeExtension<TsColors> {
  const new({
    required this.unavailable,
    required this.nowPlayingRow,
    required this.coverPlaceholder,
    required this.sourceLocal,
    required this.sources,
    required this.brandMint,
    required this.brandCyan,
    required this.brandNight,
  });

  /// Colour of the source mark of "Local".
  final Color sourceLocal;

  /// Colours of the disk marks, in the order the disks were added: blue,
  /// violet, pink, olive. Beyond 4 disks the colours are reused with an
  /// outlined shape. Contrast of at least 3:1 on surface and nowPlayingRow in
  /// both themes.
  final List<Color> sources;

  /// Text and icon of the tracks of an absent disk (contrast of at least
  /// 4.6:1).
  final Color unavailable;

  /// Background of the row being played.
  final Color nowPlayingRow;

  /// Tile shown when a track has no cover.
  final Color coverPlaceholder;

  /// Brand colours: logo, launch screen. Never behind text.
  final Color brandMint;
  final Color brandCyan;
  final Color brandNight;

  static const TsColors light = TsColors(
    unavailable: Color(0xFF6A7475),
    nowPlayingRow: Color(0xFFDDF3EE),
    coverPlaceholder: Color(0xFFE3E9E9),
    sourceLocal: Color(0xFF3F4949),
    sources: [
      Color(0xFF2F5DB8),
      Color(0xFF7048C2),
      Color(0xFFB23B78),
      Color(0xFF5D7A1C),
    ],
    brandMint: Color(0xFF74FDD3),
    brandCyan: Color(0xFF3DD6D9),
    brandNight: Color(0xFF0D1528),
  );

  static const TsColors dark = TsColors(
    unavailable: Color(0xFF8A94A2),
    nowPlayingRow: Color(0xFF123036),
    coverPlaceholder: Color(0xFF252D3A),
    sourceLocal: Color(0xFFBCC6D2),
    sources: [
      Color(0xFF8AB4FF),
      Color(0xFFC5A8FF),
      Color(0xFFFF9EC4),
      Color(0xFFC6E67A),
    ],
    brandMint: Color(0xFF74FDD3),
    brandCyan: Color(0xFF3DD6D9),
    brandNight: Color(0xFF0D1528),
  );

  /// Shortcut: `TsColors.of(context).unavailable`.
  static TsColors of(BuildContext context) =>
      Theme.of(context).extension<TsColors>()!;

  /// Colour of the mark of the disk at [diskIndex] (0 = first disk added).
  Color sourceColor(int diskIndex) => sources[diskIndex % sources.length];

  /// True when the mark is drawn as an outline (5th disk and beyond).
  static bool sourceOutlined(int diskIndex) => diskIndex >= 4;

  @override
  TsColors copyWith({
    Color? unavailable,
    Color? nowPlayingRow,
    Color? coverPlaceholder,
    Color? sourceLocal,
    List<Color>? sources,
    Color? brandMint,
    Color? brandCyan,
    Color? brandNight,
  }) {
    return TsColors(
      unavailable: unavailable ?? this.unavailable,
      nowPlayingRow: nowPlayingRow ?? this.nowPlayingRow,
      coverPlaceholder: coverPlaceholder ?? this.coverPlaceholder,
      sourceLocal: sourceLocal ?? this.sourceLocal,
      sources: sources ?? this.sources,
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
      coverPlaceholder: Color.lerp(
        coverPlaceholder,
        other.coverPlaceholder,
        t,
      )!,
      sourceLocal: Color.lerp(sourceLocal, other.sourceLocal, t)!,
      sources: [
        for (var i = 0; i < sources.length; i++)
          Color.lerp(sources[i], other.sources[i % other.sources.length], t)!,
      ],
      brandMint: Color.lerp(brandMint, other.brandMint, t)!,
      brandCyan: Color.lerp(brandCyan, other.brandCyan, t)!,
      brandNight: Color.lerp(brandNight, other.brandNight, t)!,
    );
  }
}

// Typography

abstract final class TsFonts {
  static const String display = 'Manrope';
  static const String text = 'Inter';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

abstract final class TsText {
  static const TextTheme theme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: TsFonts.display,
      fontWeight: FontWeight.w800,
      fontSize: 36,
      height: 44 / 36,
      letterSpacing: -0.72,
    ),
    headlineSmall: TextStyle(
      fontFamily: TsFonts.display,
      fontWeight: FontWeight.w800,
      fontSize: 28,
      height: 36 / 28,
      letterSpacing: -0.28,
    ),
    titleLarge: TextStyle(
      fontFamily: TsFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 28 / 22,
    ),
    titleMedium: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 24 / 16,
    ),
    titleSmall: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 20 / 14,
    ),
    bodyLarge: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16,
    ),
    bodyMedium: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 20 / 14,
    ),
    bodySmall: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 16 / 12,
    ),
    labelLarge: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 20 / 14,
    ),
    labelMedium: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 16 / 12,
      fontFeatures: TsFonts.tabular,
    ),
    labelSmall: TextStyle(
      fontFamily: TsFonts.text,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.44,
    ),
  );

  /// Title of the full-screen player.
  static const TextStyle playerTitle = TextStyle(
    fontFamily: TsFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 32 / 24,
  );
}

// Themes

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
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: TsSize.progressBar,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
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
