/// Dependency rules of `CLAUDE.md` (section Architecture), as a pure function
/// so that the rules themselves are tested on synthetic files.
library;

const _package = 'package:tuneshell/';

const _domainDartLibraries = {
  'dart:core',
  'dart:async',
  'dart:math',
  'dart:convert',
};
const _domainPackages = {'package:meta/', 'package:collection/'};

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// The URIs imported or exported by [source].
List<String> directivesOf(String source) => [
  for (final m in _directive.allMatches(source)) m.group(1)!,
];

/// Returns one message per forbidden directive of [file], a path relative to
/// `lib/` such as `domain/playback/ports/audio_engine.dart`.
List<String> violationsOf(String file, List<String> uris) => [
  for (final uri in uris)
    if (_violation(file, uri) case final String reason)
      "lib/$file: import '$uri' is forbidden ($reason)",
];

String? _violation(String file, String uri) {
  if (!uri.startsWith('dart:') && !uri.startsWith('package:')) {
    return 'rule 5: package imports only';
  }
  final layer = _layerOf(file);

  if (layer == 'domain') {
    if (uri.startsWith('dart:')) {
      return _domainDartLibraries.contains(uri)
          ? null
          : 'rule 1: domain/ is pure Dart';
    }
    final allowed =
        uri.startsWith('${_package}domain/') ||
        _domainPackages.any(uri.startsWith);
    return allowed ? null : 'rule 1: domain/ is pure Dart';
  }

  if (_isPackage(uri, 'media_kit') && !file.startsWith('data/audio/')) {
    return 'rule 4: media_kit only under data/audio/';
  }
  if (_isPackage(uri, 'drift') && !file.startsWith('data/db/')) {
    return 'rule 4: Drift only under data/db/';
  }
  if (uri == 'package:flutter/services.dart' &&
      layer != 'platform' &&
      layer != 'app') {
    return 'rule 4: channels only under platform/ and app/';
  }

  if (!uri.startsWith(_package)) return null;
  final target = uri.substring(_package.length);
  final targetLayer = _layerOf(target);

  if (layer == 'data' || layer == 'platform') {
    return targetLayer == 'domain' || targetLayer == layer
        ? null
        : 'rule 2: $layer/ imports domain/ only';
  }
  if (layer == 'features') {
    final allowed =
        targetLayer == 'domain' ||
        targetLayer == 'l10n' ||
        targetLayer == 'features' ||
        target.startsWith('app/providers/');
    return allowed
        ? null
        : 'rule 3: features/ imports domain/, l10n/ and app/providers/ only';
  }
  return null;
}

/// `package:media_kit/…` and the `media_kit_*` packages.
bool _isPackage(String uri, String name) =>
    uri.startsWith('package:$name/') || uri.startsWith('package:${name}_');

String _layerOf(String path) {
  final slash = path.indexOf('/');
  return slash < 0 ? path : path.substring(0, slash);
}
