import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// WCAG contrast ratio of two colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  /// @verifies FR-008.7
  group('contrast of the validated pairs', () {
    final cases = {
      'light': (TsSchemes.light, TsColors.light),
      'dark': (TsSchemes.dark, TsColors.dark),
    };
    for (final MapEntry(key: name, value: (scheme, colors)) in cases.entries) {
      test('text is at least 4.5:1 in $name', () {
        final pairs = {
          'onSurface on surface': (scheme.onSurface, scheme.surface),
          'onSurfaceVariant on surface': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'onPrimary on primary': (scheme.onPrimary, scheme.primary),
          'onPrimaryContainer on primaryContainer': (
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ),
          'onSecondaryContainer on secondaryContainer': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'onTertiaryContainer on tertiaryContainer': (
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
          ),
          'onError on error': (scheme.onError, scheme.error),
          'onErrorContainer on errorContainer': (
            scheme.onErrorContainer,
            scheme.errorContainer,
          ),
          'onInverseSurface on inverseSurface': (
            scheme.onInverseSurface,
            scheme.inverseSurface,
          ),
          'primary on nowPlayingRow': (scheme.primary, colors.nowPlayingRow),
          'unavailable on surface': (colors.unavailable, scheme.surface),
        };
        for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: label);
        }
      });

      test(
        'source marks are at least 3:1 on the surface and the playing row',
        () {
          for (final color in [colors.sourceLocal, ...colors.sources]) {
            expect(contrast(color, scheme.surface), greaterThanOrEqualTo(3));
            expect(
              contrast(color, colors.nowPlayingRow),
              greaterThanOrEqualTo(3),
            );
          }
        },
      );
    }
  });

  /// @verifies FR-008.1
  group('themes', () {
    test('both carry the TuneShell colours and the touch size', () {
      for (final theme in [TsTheme.light(), TsTheme.dark()]) {
        expect(theme.extension<TsColors>(), isNotNull);
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.titleLarge?.fontFamily, 'Manrope');
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      }
      expect(TsTheme.light().brightness, Brightness.light);
      expect(TsTheme.dark().brightness, Brightness.dark);
    });

    test('a dynamic scheme can replace the colour scheme only', () {
      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF123456));

      final theme = TsTheme.light(dynamicScheme: scheme);

      expect(theme.colorScheme.primary, scheme.primary);
      expect(theme.extension<TsColors>()!.brandMint, TsColors.light.brandMint);
    });

    test('digits are tabular in durations and counters', () {
      expect(
        TsText.theme.labelMedium?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  /// @verifies FR-008.4
  test('the fonts are bundled and declared, never downloaded', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('family: Manrope'));
    expect(pubspec, contains('family: Inter'));
    expect(pubspec, isNot(contains('google_fonts')));
    for (final file in [
      'Manrope-SemiBold',
      'Manrope-Bold',
      'Manrope-ExtraBold',
      'Inter-Regular',
      'Inter-Medium',
      'Inter-SemiBold',
    ]) {
      expect(pubspec, contains('assets/fonts/$file.ttf'));
      expect(File('assets/fonts/$file.ttf').existsSync(), isTrue, reason: file);
    }
    expect(File('assets/fonts/Manrope-OFL.txt').existsSync(), isTrue);
    expect(File('assets/fonts/Inter-OFL.txt').existsSync(), isTrue);
  });
}
