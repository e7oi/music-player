import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// A round avatar with the initial of a name; there is no artist image in the
/// data (FR-021.2). [tint] picks one of the two tints, so that rows differ.
///
/// @implements FR-010
class ArtistAvatar extends StatelessWidget {
  const new({
    required this.initial,
    this.size = TsSize.coverSmall,
    this.tint = 0,
    this.unavailable = false,
    super.key,
  });

  final String initial;
  final double size;

  /// Even: `primaryContainer`; odd: `secondaryContainer`.
  final int tint;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final even = tint.isEven;
    final background = unavailable
        ? scheme.surfaceContainerHigh
        : even
        ? scheme.primaryContainer
        : scheme.secondaryContainer;
    final foreground = unavailable
        ? colors.unavailable
        : even
        ? scheme.onPrimaryContainer
        : scheme.onSecondaryContainer;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(
            child: Text(
              initial,
              style:
                  (size > TsSize.coverSmall
                          ? Theme.of(context).textTheme.displaySmall
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of the Artists list, 64 dp high up to 1.3 times the text (FR-021.2).
///
/// @implements FR-010
class ArtistTile extends StatelessWidget {
  const new({
    required this.name,
    required this.subtitle,
    required this.initial,
    this.tint = 0,
    this.unavailable = false,
    this.semanticsLabel,
    this.onTap,
    this.onLongPress,
    this.customActions,
    super.key,
  });

  final String name;
  final String subtitle;
  final String initial;
  final int tint;
  final bool unavailable;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Extra actions TalkBack offers on the row.
  final Map<CustomSemanticsAction, VoidCallback>? customActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final text = Theme.of(context).textTheme;
    final fixedHeight =
        MediaQuery.textScalerOf(context).scale(1) <=
        TsSize.fixedRowMaxTextScale;
    final nameColor = unavailable ? colors.unavailable : scheme.onSurface;
    final subColor = unavailable ? colors.unavailable : scheme.onSurfaceVariant;
    return Semantics(
      label: semanticsLabel ?? '$name, $subtitle',
      button: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      customSemanticsActions: customActions,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                ArtistAvatar(
                  initial: initial,
                  tint: tint,
                  unavailable: unavailable,
                ),
                const SizedBox(width: TsSpace.m),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(color: nameColor),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
