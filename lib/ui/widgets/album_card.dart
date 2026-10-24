import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';

/// A cover with the title of an album and its second line (FR-020.2). Faded
/// with a plug icon when every disk of the album is absent (FR-020.5).
///
/// The caller gives the width; the height is the cover plus the two lines,
/// which grow with the text size.
///
/// @implements FR-010
class AlbumCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.size,
    this.artwork,
    this.marks = const [],
    this.unavailable = false,
    this.semanticsLabel,
    this.onTap,
    this.onLongPress,
    this.customActions,
    super.key,
  });

  final String title;
  final String subtitle;

  /// Side of the cover, in dp.
  final double size;
  final ImageProvider? artwork;

  /// `SourceMark`s, up to three, before the subtitle.
  final List<Widget> marks;
  final bool unavailable;

  /// Read by TalkBack instead of the visible texts.
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Extra actions TalkBack offers on the card.
  final Map<CustomSemanticsAction, VoidCallback>? customActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final text = Theme.of(context).textTheme;
    final titleColor = unavailable ? colors.unavailable : scheme.onSurface;
    final subColor = unavailable ? colors.unavailable : scheme.onSurfaceVariant;
    return Semantics(
      label: semanticsLabel ?? '$title, $subtitle',
      button: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      customSemanticsActions: customActions,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: TsRadius.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkTile(image: artwork, size: size, unavailable: unavailable),
            const SizedBox(height: TsSpace.s),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(color: titleColor),
            ),
            Row(
              children: [
                if (unavailable) ...[
                  Icon(Icons.usb_off_rounded, size: TsSpace.l, color: subColor),
                  const SizedBox(width: TsSpace.xs),
                ],
                for (final mark in marks) ...[
                  mark,
                  const SizedBox(width: TsSpace.xs),
                ],
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: subColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
