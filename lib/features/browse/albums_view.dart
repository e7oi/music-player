import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/features/browse/album_detail_page.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/album_card.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';

/// The Albums tab: a grid of covers sorted by album artist, with the alphabet
/// index (FR-020).
///
/// @implements FR-020
class AlbumsView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends ConsumerState<AlbumsView> {
  final ScrollController _scroll = ScrollController();
  late final HandleExclusion _exclusion = HandleExclusion(
    ref.read(gestureRegionsProvider),
    'albums',
  );

  /// Set by the last layout: the jump to a letter needs the row height.
  int _columns = 2;
  double _rowExtent = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exclusion.read(context);
  }

  @override
  void dispose() {
    _exclusion.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toLetter(LibraryGroups groups, String letter) {
    final index = groups.albumFirstIndex[letter];
    if (index == null || !_scroll.hasClients) return;
    _scroll.jumpTo(
      ((index ~/ _columns) * _rowExtent).clamp(
        0,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(libraryGroupsProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrowseHeader(
            title: l10n.navAlbums,
            count: groups == null ? '' : l10n.albumsCount(groups.albums.length),
            sort: groups == null || groups.albums.isEmpty
                ? null
                : l10n.albumsSort,
          ),
          Expanded(
            child: groups == null
                ? const Center(child: CircularProgressIndicator())
                : groups.albums.isEmpty
                ? BrowseEmpty(title: l10n.groupsEmptyAlbums)
                : _grid(context, groups),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, LibraryGroups groups) {
    final l10n = AppLocalizations.of(context);
    final colors = TsColors.of(context);
    final disks = ref.watch(disksByIdProvider);
    final unavailable = ref.watch(unavailableDiskIdsProvider);
    final scale = math.max(1, MediaQuery.textScalerOf(context).scale(1));
    return LayoutBuilder(
      builder: (context, constraints) {
        const margin = TsSpace.screenMargin;
        const gap = TsSpace.m;
        final usable = constraints.maxWidth - 2 * margin;
        _columns = math.max(
          2,
          math.min(
            TsSize.albumColumnsMax,
            ((usable + gap) / (TsSize.albumCardMinWidth + gap)).floor(),
          ),
        );
        final card = (usable - (_columns - 1) * gap) / _columns;
        final extent = card + TsSpace.s + TsSize.albumCardTextHeight * scale;
        _rowExtent = extent + gap;
        return AlphabetScroller(
          letters: groups.albumLetters,
          itemCount: groups.albums.length,
          onLetterSelected: (letter) => _toLetter(groups, letter),
          countLabel: l10n.albumsCount,
          letterSemantics: (letter, count) =>
              l10n.indexLetterItems(letter, l10n.albumsCount(count)),
          gridTitle: l10n.indexGoToLetter,
          onHandleRect: _exclusion.handle,
          child: GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              margin,
              TsSpace.xs,
              margin,
              TsSize.listBottomInset,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: extent,
            ),
            itemCount: groups.albums.length,
            itemBuilder: (context, i) {
              final album = groups.albums[i];
              return _AlbumGridCard(
                album: album,
                size: card,
                marks: albumMarks(album, disks, colors),
                diskName: album.available
                    ? null
                    : absentDiskName(album.disks, unavailable, disks, l10n),
              );
            },
          ),
        );
      },
    );
  }
}

/// An album of the grid, or of an artist's carousel.
class AlbumGridCard extends StatelessWidget {
  const new({
    required this.album,
    required this.size,
    required this.marks,
    required this.diskName,
    required this.onTap,
    required this.onLongPress,
    this.customActions,
    this.artwork,
    this.showArtist = true,
    super.key,
  });

  final AlbumGroup album;
  final double size;
  final List<Widget> marks;
  final ImageProvider? artwork;

  /// The absent disk to name when the album is unavailable.
  final String? diskName;

  /// The artist is the subtitle; the carousel of an artist shows the year.
  final bool showArtist;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Map<CustomSemanticsAction, VoidCallback>? customActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = album.unknownAlbum ? l10n.albumUnknown : album.title;
    final artist = album.unknownArtist ? l10n.trackUnknownArtist : album.artist;
    final subtitle = album.unknownAlbum
        ? '$artist · ${l10n.groupTracks(album.trackCount)}'
        : [if (showArtist) artist, ?album.year?.toString()].join(' · ');
    final label = '$title, $subtitle';
    return AlbumCard(
      title: title,
      subtitle: subtitle,
      size: size,
      artwork: artwork,
      marks: showArtist ? marks : const [],
      unavailable: !album.available,
      semanticsLabel: diskName == null
          ? label
          : l10n.albumNotConnected(label, diskName!),
      onTap: onTap,
      onLongPress: onLongPress,
      customActions: customActions,
    );
  }
}

class _AlbumGridCard extends ConsumerWidget {
  const new({
    required this.album,
    required this.size,
    required this.marks,
    required this.diskName,
  });

  final AlbumGroup album;
  final double size;
  final List<Widget> marks;
  final String? diskName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = album.artwork;
    return AlbumGridCard(
      album: album,
      size: size,
      marks: marks,
      diskName: diskName,
      artwork: id == null ? null : ref.watch(artworkImageProvider(id)),
      onTap: () => unawaited(openAlbum(context, album.key)),
      onLongPress: () => unawaited(
        showTracksMenu(
          context,
          ref,
          name: albumName(AppLocalizations.of(context), album),
          tracks: album.tracks,
          origin: albumOrigin(album),
        ),
      ),
      customActions: menuSemanticsActions(
        context,
        ref,
        name: albumName(AppLocalizations.of(context), album),
        tracks: album.tracks,
        origin: albumOrigin(album),
      ),
    );
  }
}

/// What the confirmations and the origin call an album.
String albumName(AppLocalizations l10n, AlbumGroup album) =>
    album.unknownAlbum ? l10n.albumUnknown : album.title;

/// Where the queue of an album says it comes from (FR-022.6).
QueueOrigin albumOrigin(AlbumGroup album) => AlbumOrigin(album.title);
