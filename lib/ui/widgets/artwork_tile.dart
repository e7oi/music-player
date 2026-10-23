import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// A cover, or a neutral tile with a note when there is none (FR-010).
/// Sizes: [TsSize.coverSmall], [TsSize.coverPanel], [TsSize.coverDetail],
/// [TsSize.coverPlayer]. Faded to 35 % when the source is unavailable.
class ArtworkTile extends StatelessWidget {
  const new({
    this.image,
    this.size = TsSize.coverSmall,
    this.unavailable = false,
    super.key,
  });

  final ImageProvider? image;
  final double size;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final radius = size <= TsSize.coverPanel
        ? TsRadius.cover
        : BorderRadius.circular(TsRadius.l);
    final placeholder = ColoredBox(
      color: colors.coverPlaceholder,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size / 2,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final cover = image;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ExcludeSemantics(
      child: Opacity(
        opacity: unavailable ? 0.35 : 1,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox.square(
            dimension: size,
            child: cover == null
                ? placeholder
                : Image(
                    // Decoded at the size shown: a cached miniature.
                    image: ResizeImage(cover, width: pixels),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  ),
          ),
        ),
      ),
    );
  }
}
