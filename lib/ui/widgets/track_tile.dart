import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';

enum TrackTileState {
  normal,
  playing,
  noArtwork,
  unavailable,
  unreadable,
  loading,
}

/// A row of a track list, 64 dp high (FR-010, HANDOFF section 6).
///
/// The whole row is the touch area. The source [mark] sits at the start of
/// the second line, before the artist. An unavailable track stays touchable
/// (the caller explains why it cannot play).
///
/// @implements FR-010
class TrackTile extends StatelessWidget {
  const new({
    required this.title,
    this.artist,
    this.duration,
    this.state = TrackTileState.normal,
    this.mark,
    this.artwork,
    this.unavailableLabel,
    this.unreadableLabel,
    this.playingLabel,
    this.semanticsLabel,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String title;
  final String? artist;

  /// Already formatted, for example `3:42`.
  final String? duration;
  final TrackTileState state;

  /// A `SourceMark`, drawn before the artist.
  final Widget? mark;
  final ImageProvider? artwork;

  /// Second line of an unavailable track, for example "Nodal · non connecté".
  final String? unavailableLabel;

  /// Second line of an unreadable track, for example "Fichier illisible".
  final String? unreadableLabel;

  /// Said by TalkBack for a playing track, for example "en lecture".
  final String? playingLabel;

  /// Read by TalkBack instead of the visible texts (title, artist, duration,
  /// state, source).
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (state == TrackTileState.loading) return const _LoadingTile();
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final text = Theme.of(context).textTheme;
    final fixedHeight =
        MediaQuery.textScalerOf(context).scale(1) <=
        TsSize.fixedRowMaxTextScale;
    final playing = state == TrackTileState.playing;
    final unavailable = state == TrackTileState.unavailable;
    final unreadable = state == TrackTileState.unreadable;
    final titleColor = unavailable
        ? colors.unavailable
        : playing
        ? scheme.primary
        : scheme.onSurface;
    final secondary = unavailable
        ? colors.unavailable
        : scheme.onSurfaceVariant;

    final status = unavailable
        ? unavailableLabel
        : unreadable
        ? unreadableLabel
        : null;
    final statusIcon = unavailable
        ? Icons.usb_off_rounded
        : unreadable
        ? Icons.error_rounded
        : null;
    final statusColor = unreadable ? scheme.error : secondary;

    return Semantics(
      label: semanticsLabel ?? _defaultLabel(),
      button: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        color: playing ? colors.nowPlayingRow : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          // BR-007, rule 9: a fixed height up to 1.3 times the text, a minimum
          // height beyond, so that large text is never cut.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: TsSize.trackRow,
              maxHeight: fixedHeight ? TsSize.trackRow : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TsSpace.screenMargin,
              ),
              child: Row(
                children: [
                  ArtworkTile(
                    image: state == TrackTileState.noArtwork ? null : artwork,
                    unavailable: unavailable,
                  ),
                  const SizedBox(width: TsSpace.m),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (playing) ...[
                              Icon(
                                Icons.equalizer_rounded,
                                size: TsSpace.l,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: TsSpace.xs),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(
                                  color: titleColor,
                                  fontWeight: playing ? FontWeight.w600 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (mark != null) ...[
                              mark!,
                              const SizedBox(width: TsSpace.xs + 2),
                            ],
                            if (statusIcon != null) ...[
                              Icon(
                                statusIcon,
                                size: TsSpace.l,
                                color: statusColor,
                              ),
                              const SizedBox(width: TsSpace.xs),
                            ],
                            Expanded(
                              child: Text(
                                status ?? artist ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium?.copyWith(
                                  color: unreadable ? scheme.error : secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: TsSpace.s),
                    Text(
                      duration!,
                      style: text.labelMedium?.copyWith(
                        color: unreadable ? scheme.error : secondary,
                      ),
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

  /// Title, artist, duration, then the state in words (FR-010.6).
  String _defaultLabel() => [
    title,
    ?artist,
    ?duration,
    if (state == TrackTileState.playing) ?playingLabel,
    if (state == TrackTileState.unavailable) ?unavailableLabel,
    if (state == TrackTileState.unreadable) ?unreadableLabel,
  ].join(', ');
}

/// Skeleton row shown while a list loads.
class _LoadingTile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final fill = TsColors.of(context).coverPlaceholder;
    Widget bar(double width) => DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(TsRadius.xs),
      ),
      child: SizedBox(width: width, height: TsSpace.m),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: TsSize.trackRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: TsRadius.cover,
                ),
                child: const SizedBox.square(dimension: TsSize.coverSmall),
              ),
              const SizedBox(width: TsSpace.m),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(TsSize.coverPanel + TsSize.coverSmall),
                    const SizedBox(height: TsSpace.s),
                    bar(TsSize.coverPanel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
