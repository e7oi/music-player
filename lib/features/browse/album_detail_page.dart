import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/albums_view.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/group_actions.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';

/// Opens the detail of an album in the current tab (FR-020.8, ADR-016).
Future<void> openAlbum(BuildContext context, String key) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => AlbumDetailPage(albumKey: key)));

/// An album: its header, "Play" and "Shuffle", and its tracks by disc then
/// track number (FR-020.9 to FR-020.11).
///
/// @implements FR-020
class AlbumDetailPage extends ConsumerWidget {
  const new({required this.albumKey, super.key});

  final String albumKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(libraryGroupsProvider);
    final album = groups?.albums.where((a) => a.key == albumKey).firstOrNull;
    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0),
      body: album == null
          ? Center(
              child: groups == null
                  ? const CircularProgressIndicator()
                  : Text(l10n.groupNotFound),
            )
          : _Detail(album: album),
    );
  }
}

class _Detail extends ConsumerWidget {
  const new({required this.album});

  final AlbumGroup album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final id = album.artwork;
    final artist = album.unknownArtist ? l10n.trackUnknownArtist : album.artist;
    final disks = ref.watch(disksByIdProvider);
    final unavailable = ref.watch(unavailableDiskIdsProvider);
    final current = ref.watch(
      playerStateProvider.select((s) => s.value?.currentTrack),
    );
    final origin = albumOrigin(album);
    final meta = [
      if (album.discCount > 1) l10n.albumDiscs(album.discCount),
      l10n.groupTracks(album.trackCount),
      durationText(l10n, album.duration),
    ].join(' · ');
    final line = [?album.year?.toString(), ?album.genre].join(' · ');

    // Light entries; the rows are built when they scroll into view.
    final entries = <Object>[];
    int? disc;
    for (var i = 0; i < album.tracks.length; i++) {
      final trackDisc = _disc(album.tracks[i]);
      if (album.discCount > 1 && trackDisc != disc) {
        disc = trackDisc;
        entries.add(l10n.playerDiscNumber(trackDisc));
      }
      entries.add(i);
    }

    Widget row(int i) {
      final track = album.tracks[i];
      return _TrackRow(
        track: track,
        number: _number(track) ?? i + 1,
        playing: track.track == current,
        unavailable: unavailable.contains(track.disk),
        showMark: album.disks.length > 1,
        disk: disks[track.disk],
        onTap: () {
          if (unavailable.contains(track.disk)) {
            explainUnavailable(context, ref, track.disk);
            return;
          }
          playOrExplain(
            context,
            ref,
            tracks: album.tracks,
            origin: origin,
            startIndex: i,
          );
        },
        onLongPress: () => unawaited(showTrackMenu(context, ref, track)),
        customActions: menuSemanticsActions(
          context,
          ref,
          name: track.displayTitle,
          tracks: [track],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TsSpace.screenMargin,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArtworkTile(
                      size: TsSize.coverDetail,
                      image: id == null
                          ? null
                          : ref.watch(artworkImageProvider(id)),
                      unavailable: !album.available,
                    ),
                    const SizedBox(width: TsSpace.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            albumName(l10n, album),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge,
                          ),
                          Text(
                            artist,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          if (line.isNotEmpty)
                            Text(
                              line,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            meta,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TsSpace.screenMargin,
                  vertical: TsSpace.l,
                ),
                child: Wrap(
                  spacing: TsSpace.s,
                  runSpacing: TsSpace.s,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.albumPlay),
                      onPressed: () => playOrExplain(
                        context,
                        ref,
                        tracks: album.tracks,
                        origin: origin,
                        shuffle: false,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(l10n.playerShuffle),
                      onPressed: () => playOrExplain(
                        context,
                        ref,
                        tracks: album.tracks,
                        origin: origin,
                        shuffle: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return entry is String ? _DiscHeader(entry) : row(entry as int);
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: TsSpace.xl)),
      ],
    );
  }
}

/// The track number of the tag, or null when absent or below one (BR-010).
int? _number(LibraryTrack track) {
  final number = track.info.trackNumber;
  return number == null || number < 1 ? null : number;
}

/// A disc number below one counts as disc one (BR-010, rule 6).
int _disc(LibraryTrack track) {
  final disc = track.info.discNumber;
  return disc == null || disc < 1 ? 1 : disc;
}

class _DiscHeader extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TsSpace.screenMargin,
      TsSpace.m,
      TsSpace.screenMargin,
      TsSpace.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class _TrackRow extends StatelessWidget {
  const new({
    required this.track,
    required this.number,
    required this.playing,
    required this.unavailable,
    required this.showMark,
    required this.disk,
    required this.onTap,
    required this.onLongPress,
    required this.customActions,
  });

  final LibraryTrack track;
  final int number;
  final bool playing;
  final bool unavailable;
  final bool showMark;
  final Disk? disk;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final text = Theme.of(context).textTheme;
    final titleColor = unavailable
        ? colors.unavailable
        : playing
        ? scheme.primary
        : scheme.onSurface;
    final numberColor = unavailable
        ? colors.unavailable
        : playing
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final duration = track.info.duration;
    final name = sourceName(disk, l10n);
    final mark = showMark ? sourceMarkOf(disk, colors) : null;
    final label = [
      l10n.playerTrackNumber(number),
      track.displayTitle,
      if (duration != null) formatClock(duration),
      if (playing) l10n.trackPlaying,
      if (unavailable && name != null) l10n.trackNeedsDisk(name),
      if (showMark && name != null) l10n.trackSource(name),
    ].join(', ');
    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      onLongPress: onLongPress,
      customSemanticsActions: customActions,
      excludeSemantics: true,
      child: Material(
        color: playing ? colors.nowPlayingRow : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TsSize.albumTrackRow),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TsSpace.screenMargin,
              ),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: TsSpace.xxl),
                    child: playing
                        ? Icon(
                            Icons.play_arrow_rounded,
                            size: TsSpace.xl,
                            color: numberColor,
                          )
                        : Text(
                            '$number',
                            style: text.labelMedium?.copyWith(
                              color: numberColor,
                            ),
                          ),
                  ),
                  if (unavailable) ...[
                    Icon(
                      Icons.usb_off_rounded,
                      size: TsSpace.l,
                      color: numberColor,
                    ),
                    const SizedBox(width: TsSpace.xs),
                  ],
                  Expanded(
                    child: Text(
                      track.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: playing ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (mark != null) ...[const SizedBox(width: TsSpace.s), mark],
                  if (duration != null) ...[
                    const SizedBox(width: TsSpace.s),
                    Text(
                      formatClock(duration),
                      style: text.labelMedium?.copyWith(color: numberColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
