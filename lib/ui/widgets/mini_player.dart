import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';

/// The shared element between the mini player and the full-screen player.
const Object playerCoverHeroTag = 'tuneshell-player-cover';

/// The track playing, always above the navigation (FR-016, HANDOFF section 5).
///
/// Touching the left part or dragging up opens the player; the three buttons
/// are 48 dp. The progress bar is a slot ([progress]) so that the parts that
/// do not move are not rebuilt at each tick.
///
/// @implements FR-016
class MiniPlayer extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.playing,
    required this.progress,
    required this.openLabel,
    required this.previousLabel,
    required this.playLabel,
    required this.pauseLabel,
    required this.nextLabel,
    required this.onOpen,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    this.artist = true,
    this.mark,
    this.artwork,
    this.sourceLost = false,
    this.openSemanticsLabel,
    super.key,
  });

  final String title;

  /// The artist, or the reason playback stopped when [sourceLost].
  final String subtitle;

  /// The subtitle is an artist (false: a plain text, such as "Unknown").
  final bool artist;

  /// A `SourceMark` of [TsSize.sourceMarkMini], before the subtitle.
  final Widget? mark;
  final ImageProvider? artwork;
  final bool playing;

  /// The disk of the track left: the subtitle says so in the warning colour,
  /// with an icon, and the cover fades (FR-016.7).
  final bool sourceLost;
  final Widget progress;
  final String openLabel;
  final String previousLabel;
  final String playLabel;
  final String pauseLabel;
  final String nextLabel;
  final String? openSemanticsLabel;
  final VoidCallback onOpen;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final subColor = sourceLost ? scheme.tertiary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(TsSpace.s),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: TsRadius.card,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TsSize.miniPlayer),
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) < 0) onOpen();
                      },
                      child: Semantics(
                        button: true,
                        label: openSemanticsLabel ?? openLabel,
                        onTap: onOpen,
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: onOpen,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: TsSpace.s,
                              top: TsSpace.s,
                              bottom: TsSpace.s,
                            ),
                            child: Row(
                              children: [
                                Hero(
                                  tag: playerCoverHeroTag,
                                  child: ArtworkTile(
                                    image: artwork,
                                    fade: sourceLost ? 0.5 : 1,
                                  ),
                                ),
                                const SizedBox(width: TsSpace.m),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.titleSmall?.copyWith(
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (sourceLost) ...[
                                            Icon(
                                              Icons.usb_off_rounded,
                                              size: TsSize.sourceMarkMini,
                                              color: subColor,
                                            ),
                                            const SizedBox(width: TsSpace.xs),
                                          ] else if (mark != null) ...[
                                            mark!,
                                            const SizedBox(width: TsSpace.xs),
                                          ],
                                          Expanded(
                                            child: Text(
                                              subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.labelMedium?.copyWith(
                                                color: subColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _Button(
                    icon: Icons.skip_previous_rounded,
                    tooltip: previousLabel,
                    onPressed: onPrevious,
                  ),
                  SizedBox.square(
                    dimension: TsSize.touchTarget,
                    child: IconButton.filled(
                      tooltip: playing ? pauseLabel : playLabel,
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: onPlayPause,
                    ),
                  ),
                  _Button(
                    icon: Icons.skip_next_rounded,
                    tooltip: nextLabel,
                    onPressed: onNext,
                  ),
                  const SizedBox(width: TsSpace.xs),
                ],
              ),
              Positioned(
                left: TsSpace.m,
                right: TsSpace.m,
                bottom: 0,
                child: progress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: TsSize.touchTarget,
    child: IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
  );
}

/// The thin bar at the foot of the [MiniPlayer]; [value] is 0 to 1.
class MiniPlayerProgress extends StatelessWidget {
  const new({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: TsSize.miniProgress,
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.outlineVariant),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              heightFactor: 1,
              child: ColoredBox(color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
