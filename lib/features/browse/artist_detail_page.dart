import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/album_detail_page.dart';
import 'package:tuneshell/features/browse/albums_view.dart';
import 'package:tuneshell/features/browse/artists_view.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/group_actions.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artist_tile.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// Opens the detail of an artist in the current tab (FR-021.7, ADR-016).
Future<void> openArtist(BuildContext context, String key) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ArtistDetailPage(artistKey: key)),
    );

/// An artist: header, "Play all" and "Shuffle", the albums in a carousel,
/// then every track, album by album (FR-021.8 to FR-021.10).
///
/// @implements FR-021
class ArtistDetailPage extends ConsumerWidget {
  const new({required this.artistKey, super.key});

  final String artistKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(libraryGroupsProvider);
    final artist = groups?.artists.where((a) => a.key == artistKey).firstOrNull;
    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0),
      body: artist == null
          ? Center(
              child: groups == null
                  ? const CircularProgressIndicator()
                  : Text(l10n.artistNotFound),
            )
          : _Detail(artist: artist),
    );
  }
}

class _Detail extends ConsumerWidget {
  const new({required this.artist});

  final ArtistGroup artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final disks = ref.watch(disksByIdProvider);
    final unavailable = ref.watch(unavailableDiskIdsProvider);
    final current = ref.watch(
      playerStateProvider.select((s) => s.value?.currentTrack),
    );
    final name = artist.unknown ? l10n.trackUnknownArtist : artist.name;
    final origin = artistOrigin(artist);
    final meta = [
      l10n.artistSummary(artist.albums.length, artist.trackCount),
      durationText(l10n, artist.duration),
    ].join(' · ');
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final carouselHeight =
        TsSize.carouselCard +
        TsSpace.s +
        TsSize.albumCardTextHeight * (scale < 1 ? 1 : scale);

    // Light entries; the rows are built when they scroll into view.
    final entries = <({AlbumGroup album, LibraryTrack track})>[
      for (final album in artist.albums)
        for (final track in album.tracks) (album: album, track: track),
    ];

    Widget row(int start) {
      final (:album, :track) = entries[start];
      final isOff = unavailable.contains(track.disk);
      final diskName = sourceName(disks[track.disk], l10n);
      final albumTitle = albumName(l10n, album);
      final duration = track.info.duration;
      return Semantics(
        customSemanticsActions: menuSemanticsActions(
          context,
          ref,
          name: track.displayTitle,
          tracks: [track],
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final id = track.artwork;
            return TrackTile(
              title: track.displayTitle,
              artist: albumTitle,
              duration: duration == null ? null : formatClock(duration),
              state: isOff
                  ? TrackTileState.unavailable
                  : track.track == current
                  ? TrackTileState.playing
                  : TrackTileState.normal,
              mark: sourceMarkOf(disks[track.disk], colors),
              artwork: id == null ? null : ref.watch(artworkImageProvider(id)),
              unavailableLabel: l10n.trackNotConnected(albumTitle),
              playingLabel: l10n.trackPlaying,
              semanticsLabel: [
                track.displayTitle,
                albumTitle,
                if (duration != null) formatClock(duration),
                if (track.track == current) l10n.trackPlaying,
                if (isOff && diskName != null) l10n.trackNeedsDisk(diskName),
                ?diskName == null ? null : l10n.trackSource(diskName),
              ].join(', '),
              onTap: () => isOff
                  ? explainUnavailable(context, ref, track.disk)
                  : playOrExplain(
                      context,
                      ref,
                      tracks: artist.tracks,
                      origin: origin,
                      startIndex: start,
                    ),
              onLongPress: () => unawaited(showTrackMenu(context, ref, track)),
            );
          },
        ),
      );
    }

    Widget section(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(
        TsSpace.screenMargin,
        TsSpace.l,
        TsSpace.screenMargin,
        TsSpace.s,
      ),
      child: Semantics(
        header: true,
        child: Text(label, style: text.titleMedium),
      ),
    );

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
                  children: [
                    ArtistAvatar(
                      initial: artist.unknown
                          ? '?'
                          : alphabetInitial(artist.name),
                      size: TsSize.coverPanel,
                      unavailable: !artist.available,
                    ),
                    const SizedBox(width: TsSpace.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineSmall,
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
                      label: Text(l10n.artistPlayAll),
                      onPressed: () => playOrExplain(
                        context,
                        ref,
                        tracks: artist.tracks,
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
                        tracks: artist.tracks,
                        origin: origin,
                        shuffle: true,
                      ),
                    ),
                  ],
                ),
              ),
              section(l10n.navAlbums),
              SizedBox(
                height: carouselHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TsSpace.screenMargin,
                  ),
                  itemCount: artist.albums.length,
                  separatorBuilder: (_, _) => const SizedBox(width: TsSpace.m),
                  itemBuilder: (context, i) {
                    final album = artist.albums[i];
                    final id = album.artwork;
                    return SizedBox(
                      width: TsSize.carouselCard,
                      child: AlbumGridCard(
                        album: album,
                        size: TsSize.carouselCard,
                        marks: const [],
                        showArtist: false,
                        diskName: album.available
                            ? null
                            : absentDiskName(
                                album.disks,
                                unavailable,
                                disks,
                                l10n,
                              ),
                        artwork: id == null
                            ? null
                            : ref.watch(artworkImageProvider(id)),
                        onTap: () => unawaited(openAlbum(context, album.key)),
                        onLongPress: () => unawaited(
                          showTracksMenu(
                            context,
                            ref,
                            name: albumName(l10n, album),
                            tracks: album.tracks,
                            origin: albumOrigin(album),
                          ),
                        ),
                        customActions: menuSemanticsActions(
                          context,
                          ref,
                          name: albumName(l10n, album),
                          tracks: album.tracks,
                          origin: albumOrigin(album),
                        ),
                      ),
                    );
                  },
                ),
              ),
              section(l10n.navTracks),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) => row(index),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: TsSpace.xl)),
      ],
    );
  }
}
