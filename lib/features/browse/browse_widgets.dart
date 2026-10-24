import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The title of a view with its count and its sort label under it, like the
/// Tracks view (FR-020.1, FR-021.1).
class BrowseHeader extends StatelessWidget {
  const new({required this.title, required this.count, this.sort, super.key});

  final String title;
  final String count;

  /// The label of the only sort, not interactive.
  final String? sort;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
          child: SizedBox(
            height: TsSize.touchTarget + TsSpace.s,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                child: Text(title, style: text.headlineSmall),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TsSpace.screenMargin,
            vertical: TsSpace.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (sort != null)
                Text(
                  sort!,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A view with nothing in it: what is missing and where to look (FR-020.7).
class BrowseEmpty extends StatelessWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: TsSpace.s),
            Text(
              l10n.groupsEmptyHint,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the handle of an index out of the Back gesture while its view is in
/// front (FR-013.2, ADR-016): the rectangle is converted to physical pixels
/// and reported under this view's own key.
///
/// @decision ADR-016
class HandleExclusion {
  new(this._regions, this._owner);

  final GestureRegions _regions;
  final Object _owner;
  Rect? _handle;
  double _ratio = 1;
  bool _inFront = true;

  /// Read in `didChangeDependencies`: the context cannot be asked later.
  void read(BuildContext context) {
    _ratio = View.of(context).devicePixelRatio;
    // IndexedStack no longer stops the tickers of the tabs it hides: it says
    // which one is visible through `Visibility.of`. A detail pushed over the
    // view stops its tickers.
    _inFront = TickerMode.valuesOf(context).enabled && Visibility.of(context);
    _send();
  }

  void handle(Rect? rect) {
    _handle = rect;
    _send();
  }

  void dispose() => unawaited(_regions.set(_owner, const []));

  void _send() {
    final rect = _handle;
    final shown = rect != null && _inFront;
    unawaited(
      _regions.set(_owner, [
        if (shown)
          Rect.fromLTRB(
            rect.left * _ratio,
            rect.top * _ratio,
            rect.right * _ratio,
            rect.bottom * _ratio,
          ),
      ]),
    );
  }
}

/// The source marks of an album: up to three, one per disk, in track order
/// (FR-020.3).
List<Widget> albumMarks(
  AlbumGroup album,
  Map<DiskId, Disk> disks,
  TsColors colors,
) => [for (final id in album.disks.take(3)) ?sourceMarkOf(disks[id], colors)];

/// "58 min" or "2 h 04" (FR-020.9, FR-021.8).
String durationText(AppLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return l10n.durationMinutes(minutes);
  return l10n.durationHours(
    minutes ~/ 60,
    (minutes % 60).toString().padLeft(2, '0'),
  );
}

/// The name of the first absent disk of a group, for "…, unavailable: SSD not
/// connected".
String? absentDiskName(
  List<DiskId> disks,
  Set<DiskId> unavailable,
  Map<DiskId, Disk> byId,
  AppLocalizations l10n,
) {
  for (final id in disks) {
    if (unavailable.contains(id)) {
      return sourceName(byId[id], l10n) ?? id.value;
    }
  }
  return null;
}
