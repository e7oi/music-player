import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// A fake list of 5,000 tracks with the alphabet index and the "current track"
/// button, to judge fluidity and gestures on the device (FR-010.7).
class IndexDemoPage extends StatefulWidget {
  const new({required this.dark, super.key});

  final bool dark;

  @override
  State<IndexDemoPage> createState() => _IndexDemoPageState();
}

class _IndexDemoPageState extends State<IndexDemoPage> {
  static const _count = 5000;
  static const _playing = 2600;

  final _controller = ScrollController();
  late final List<String> _titles = _makeTitles();
  late final Map<String, int> _first = firstIndexes(_titles);
  late final List<AlphabetLetter> _letters = buildLetters(_titles);
  var _alignStart = false;

  /// Sorted fictional titles, spread over the alphabet and "#".
  static List<String> _makeTitles() {
    const alphabet = 'ABCDEFGHIJKLMNOPRSTUVWZ';
    final titles = <String>[
      for (var i = 0; i < 200; i++) '${i.toString().padLeft(2, '0')} - sample',
      for (var i = 0; i < _count - 200; i++) _title(alphabet, i),
    ]..sort();
    return titles;
  }

  static String _title(String alphabet, int i) {
    final number = (i ~/ alphabet.length).toString().padLeft(3, '0');
    return '${alphabet[i % alphabet.length]}$number sample';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jump(String letter) {
    final index = _first[letter];
    if (index == null) return;
    _controller.jumpTo(index * TsSize.trackRow);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.dark ? TsTheme.dark() : TsTheme.light();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final colors = TsColors.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('5,000 rows'),
              actions: [
                Switch(
                  value: _alignStart,
                  onChanged: (v) => setState(() => _alignStart = v),
                ),
              ],
            ),
            body: AlphabetScroller(
              letters: _letters,
              itemCount: _count,
              alignStart: _alignStart,
              gridTitle: 'Go to letter',
              countLabel: (count) => '$count tracks',
              letterSemantics: (letter, count) =>
                  'Letter $letter, $count tracks',
              onLetterSelected: _jump,
              child: ListView.builder(
                controller: _controller,
                itemExtent: TsSize.trackRow,
                itemCount: _count,
                itemBuilder: (context, i) => TrackTile(
                  title: _titles[i],
                  artist: 'Fictional artist',
                  duration: '3:${(i % 60).toString().padLeft(2, '0')}',
                  state: i == _playing
                      ? TrackTileState.playing
                      : TrackTileState.normal,
                  mark: i.isEven
                      ? SourceMark.local(colors)
                      : SourceMark.disk(i % 5, colors),
                ),
              ),
            ),
            floatingActionButton: JumpToCurrentFab(
              label: 'En cours',
              onPressed: () => _controller.animateTo(
                _playing * TsSize.trackRow,
                duration: TsMotion.long,
                curve: TsMotion.standard,
              ),
            ),
          );
        },
      ),
    );
  }
}
