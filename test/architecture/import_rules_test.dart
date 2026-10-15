import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_rules.dart';

void main() {
  group('rules on synthetic files', () {
    void expectForbidden(String file, String uri, String rule) {
      final violations = violationsOf(file, [uri]);
      expect(violations, hasLength(1), reason: '$file -> $uri');
      expect(violations.single, contains('lib/$file'));
      expect(violations.single, contains(uri));
      expect(violations.single, contains(rule));
    }

    void expectAllowed(String file, String uri) =>
        expect(violationsOf(file, [uri]), isEmpty, reason: '$file -> $uri');

    test('rule 1: domain/ is pure Dart', () {
      const file = 'domain/playback/x.dart';
      expectForbidden(file, 'package:flutter/foundation.dart', 'rule 1');
      expectForbidden(file, 'dart:io', 'rule 1');
      expectForbidden(file, 'dart:ui', 'rule 1');
      expectForbidden(
        file,
        'package:flutter_riverpod/flutter_riverpod.dart',
        'rule 1',
      );
      expectForbidden(file, 'package:media_kit/media_kit.dart', 'rule 1');
      expectForbidden(file, 'package:musicplayer/data/audio/x.dart', 'rule 1');
      expectAllowed(file, 'dart:async');
      expectAllowed(file, 'dart:math');
      expectAllowed(file, 'dart:convert');
      expectAllowed(file, 'package:meta/meta.dart');
      expectAllowed(file, 'package:collection/collection.dart');
      expectAllowed(
        file,
        'package:musicplayer/domain/library/model/track.dart',
      );
    });

    test('rule 2: data/ and platform/ import domain/ only', () {
      expectForbidden(
        'data/audio/x.dart',
        'package:musicplayer/features/home/x.dart',
        'rule 2',
      );
      expectForbidden(
        'platform/x.dart',
        'package:musicplayer/app/app.dart',
        'rule 2',
      );
      expectAllowed(
        'data/audio/x.dart',
        'package:musicplayer/domain/playback/ports/audio_engine.dart',
      );
      expectAllowed('platform/x.dart', 'package:musicplayer/platform/y.dart');
    });

    test('rule 3: features/ never imports data/ or platform/', () {
      const file = 'features/home/x.dart';
      expectForbidden(file, 'package:musicplayer/data/audio/x.dart', 'rule 3');
      expectForbidden(file, 'package:musicplayer/platform/x.dart', 'rule 3');
      expectForbidden(file, 'package:musicplayer/app/router.dart', 'rule 3');
      expectAllowed(file, 'package:musicplayer/app/providers/player.dart');
      expectAllowed(
        file,
        'package:musicplayer/l10n/generated/app_localizations.dart',
      );
      expectAllowed(file, 'package:flutter/material.dart');
    });

    test('rule 4: media_kit, Drift and channels stay in their place', () {
      expectForbidden(
        'app/app.dart',
        'package:media_kit/media_kit.dart',
        'rule 4',
      );
      expectForbidden(
        'main.dart',
        'package:media_kit_libs_audio/media_kit_libs_audio.dart',
        'rule 4',
      );
      expectForbidden(
        'data/audio/x.dart',
        'package:drift/drift.dart',
        'rule 4',
      );
      expectForbidden(
        'features/home/x.dart',
        'package:flutter/services.dart',
        'rule 4',
      );
      expectAllowed('data/audio/x.dart', 'package:media_kit/media_kit.dart');
      expectAllowed('data/db/x.dart', 'package:drift/drift.dart');
      expectAllowed('platform/x.dart', 'package:flutter/services.dart');
      expectAllowed('app/app.dart', 'package:flutter/services.dart');
    });

    test('rule 5: no relative import', () {
      expectForbidden('app/app.dart', '../domain/x.dart', 'rule 5');
    });

    test('directives are read from the source', () {
      expect(
        directivesOf(
          "import 'dart:async';\n"
          'import "package:meta/meta.dart" show immutable;\n'
          "export 'package:musicplayer/domain/x.dart';\n"
          "// import 'commented.dart';\n",
        ),
        [
          'dart:async',
          'package:meta/meta.dart',
          'package:musicplayer/domain/x.dart',
        ],
      );
    });
  });

  /// Generated code is excluded, as from the analysis (`CLAUDE.md`, Tests).
  bool isHandWritten(String path) =>
      path.endsWith('.dart') &&
      !path.endsWith('.g.dart') &&
      !path.contains('l10n/generated/');

  test('lib/ follows the dependency rules', () {
    final lib = Directory('lib');
    final violations = <String>[
      for (final entity in lib.listSync(recursive: true))
        if (entity is File && isHandWritten(entity.path))
          ...violationsOf(
            entity.path.substring(lib.path.length + 1),
            directivesOf(entity.readAsStringSync()),
          ),
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
