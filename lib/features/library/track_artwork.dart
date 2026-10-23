import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';

/// The artwork of a track, or a note icon when it has none (FR-007.7).
/// Temporary until the MPL-016 mock-ups exist.
class TrackArtwork extends ConsumerWidget {
  const new({required this.artwork, this.size = 48, super.key});

  final String? artwork;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = SizedBox.square(
      dimension: size,
      child: const Icon(Icons.music_note),
    );
    final id = artwork;
    final image = id == null ? null : ref.watch(artworkImageProvider(id));
    if (image == null) return placeholder;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox.square(
      dimension: size,
      child: Image(
        image: ResizeImage(image, width: pixels),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
