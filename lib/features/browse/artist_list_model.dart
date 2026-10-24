import 'package:flutter/foundation.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// A line of the Artists list: a letter, or an artist (FR-021.3).
@immutable
sealed class ArtistItem {
  const new();
}

final class ArtistHeader extends ArtistItem {
  const new(this.letter);

  final String letter;
}

final class ArtistEntry extends ArtistItem {
  const new(this.artist, this.position);

  final ArtistGroup artist;

  /// Position among the artists: the avatar tint alternates with it.
  final int position;
}

/// The Artists list with its letter headers, and where each letter starts,
/// so that the index can jump without measuring (ADR-016).
///
/// @implements FR-021
class ArtistListModel {
  new _(this.items, this._firstItem);

  factory build(List<ArtistGroup> artists) {
    final items = <ArtistItem>[];
    final firstItem = <String, int>{};
    String? current;
    for (var i = 0; i < artists.length; i++) {
      final artist = artists[i];
      final letter = artist.unknown ? '#' : alphabetKey(artist.name);
      if (letter != current) {
        current = letter;
        firstItem[letter] = items.length;
        items.add(ArtistHeader(letter));
      }
      items.add(ArtistEntry(artist, i));
    }
    return ArtistListModel._(List.unmodifiable(items), firstItem);
  }

  final List<ArtistItem> items;
  final Map<String, int> _firstItem;

  /// Scroll offset of the header of [letter], or null when it has no artist.
  double? offsetOf(
    String letter, {
    required double headerExtent,
    required double rowExtent,
  }) {
    final index = _firstItem[letter];
    if (index == null) return null;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += items[i] is ArtistHeader ? headerExtent : rowExtent;
    }
    return offset;
  }
}
