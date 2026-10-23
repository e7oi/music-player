import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

enum JumpDirection { up, down }

/// The "now playing" button of a long list (FR-010). Shown only while the
/// current track is out of view; points toward it; shows "last played" when
/// nothing plays; folds to its icon during a fast scroll.
///
/// @implements FR-010
class JumpToCurrentFab extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.direction = JumpDirection.down,
    this.visible = true,
    this.lastPlayed = false,
    this.folded = false,
    super.key,
  });

  /// "En cours", or "Dernière jouée" when [lastPlayed].
  final String label;
  final VoidCallback onPressed;
  final JumpDirection direction;

  /// Fades and scales in and out (the caller decides from the visible rows).
  final bool visible;

  /// Nothing plays: the button leads to the last played track, less
  /// insistently.
  final bool lastPlayed;

  /// Icon only, during a fast scroll.
  final bool folded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // BR-007, rule 7: no motion when the user asked for none.
    final still = MediaQuery.disableAnimationsOf(context);
    final background = lastPlayed
        ? scheme.surfaceContainerHigh
        : scheme.primaryContainer;
    final foreground = lastPlayed
        ? scheme.onSurface
        : scheme.onPrimaryContainer;
    final arrow = direction == JumpDirection.up
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: still ? Duration.zero : TsMotion.medium,
      curve: TsMotion.standard,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: still ? Duration.zero : TsMotion.medium,
        child: IgnorePointer(
          ignoring: !visible,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: onPressed,
            child: Material(
              color: background,
              elevation: 3,
              borderRadius: BorderRadius.circular(TsRadius.l),
              child: InkWell(
                borderRadius: BorderRadius.circular(TsRadius.l),
                onTap: onPressed,
                child: AnimatedSize(
                  duration: still ? Duration.zero : TsMotion.short,
                  child: SizedBox(
                    height: TsSize.fab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TsSpace.l,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            lastPlayed
                                ? Icons.history_rounded
                                : Icons.equalizer_rounded,
                            color: foreground,
                          ),
                          if (!lastPlayed) Icon(arrow, color: foreground),
                          if (!folded) ...[
                            const SizedBox(width: TsSpace.s),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: foreground),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
