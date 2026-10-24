import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/artist_detail_page.dart';
import 'package:tuneshell/features/browse/artist_list_model.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';
import 'package:tuneshell/ui/widgets/artist_tile.dart';

/// The Artists tab: a list with letter headers and the alphabet index
/// (FR-021).
///
/// @implements FR-021
class ArtistsView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends ConsumerState<ArtistsView> {
  final ScrollController _scroll = ScrollController();
  late final HandleExclusion _exclusion = HandleExclusion(
    ref.read(gestureRegionsProvider),
    'artists',
  );

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

  double get _scale => math.max(1, MediaQuery.textScalerOf(context).scale(1));

  /// Row height: 64 dp up to 1.3 times the text, proportional beyond.
  double get _rowExtent => _scale <= TsSize.fixedRowMaxTextScale
      ? TsSize.trackRow
      : TsSize.trackRow * _scale;

  double get _headerExtent => TsSize.letterHeader * _scale;

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
            title: l10n.navArtists,
            count: groups == null
                ? ''
                : l10n.artistsCount(groups.artists.length),
          ),
          Expanded(
            child: groups == null
                ? const Center(child: CircularProgressIndicator())
                : groups.artists.isEmpty
                ? BrowseEmpty(title: l10n.groupsEmptyArtists)
                : _list(context, groups),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, LibraryGroups groups) {
    final l10n = AppLocalizations.of(context);
    final model = ref.watch(artistListModelProvider)!;
    final disks = ref.watch(disksByIdProvider);
    final unavailable = ref.watch(unavailableDiskIdsProvider);
    return AlphabetScroller(
      letters: groups.artistLetters,
      itemCount: groups.artists.length,
      onLetterSelected: (letter) {
        final offset = model.offsetOf(
          letter,
          headerExtent: _headerExtent,
          rowExtent: _rowExtent,
        );
        if (offset == null || !_scroll.hasClients) return;
        _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
      },
      countLabel: l10n.artistsCountShort,
      letterSemantics: (letter, count) =>
          l10n.indexLetterItems(letter, l10n.artistsCountShort(count)),
      gridTitle: l10n.indexGoToLetter,
      onHandleRect: _exclusion.handle,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverVariedExtentList(
            itemExtentBuilder: (index, _) =>
                model.items[index] is ArtistHeader ? _headerExtent : _rowExtent,
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = model.items[index];
              return switch (item) {
                ArtistHeader(:final letter) => _LetterHeader(letter),
                ArtistEntry(:final artist, :final position) => _row(
                  context,
                  l10n,
                  artist,
                  position,
                  disks,
                  unavailable,
                ),
              };
            }, childCount: model.items.length),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: TsSize.listBottomInset),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l10n,
    ArtistGroup artist,
    int position,
    Map<DiskId, Disk> disks,
    Set<DiskId> unavailable,
  ) {
    final summary = artistSummaryText(l10n, artist);
    final diskName = artist.available
        ? null
        : absentDiskName(
            [for (final a in artist.albums) ...a.disks],
            unavailable,
            disks,
            l10n,
          );
    final subtitle = diskName == null
        ? summary
        : l10n.artistNotConnected(summary, diskName);
    final name = artist.unknown ? l10n.trackUnknownArtist : artist.name;
    return ArtistTile(
      name: name,
      subtitle: subtitle,
      initial: artist.unknown ? '?' : alphabetInitial(artist.name),
      tint: position,
      unavailable: !artist.available,
      semanticsLabel: '$name, $subtitle',
      onTap: () => unawaited(openArtist(context, artist.key)),
      onLongPress: () => unawaited(
        showTracksMenu(
          context,
          ref,
          name: name,
          tracks: artist.tracks,
          origin: artistOrigin(artist),
        ),
      ),
      customActions: menuSemanticsActions(
        context,
        ref,
        name: name,
        tracks: artist.tracks,
        origin: artistOrigin(artist),
      ),
    );
  }
}

/// "3 albums · 31 tracks", or the count of untagged tracks for the unknown
/// artist (FR-021.2).
String artistSummaryText(AppLocalizations l10n, ArtistGroup artist) =>
    artist.unknown
    ? l10n.artistUnknownSummary(artist.trackCount)
    : l10n.artistSummary(artist.albums.length, artist.trackCount);

/// Where the queue of an artist says it comes from (FR-022.6).
QueueOrigin artistOrigin(ArtistGroup artist) => ArtistOrigin(artist.name);

/// The first letter of a name, upper case, for an avatar.
String alphabetInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? '?'
      : String.fromCharCode(trimmed.runes.first).toUpperCase();
}

class _LetterHeader extends StatelessWidget {
  const new(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    ),
  );
}
