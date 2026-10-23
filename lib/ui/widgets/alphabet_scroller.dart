import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// Alphabet index over a long list (HANDOFF section 6.1, FR-010.4).
///
/// At rest only a thin handle sits against the edge (faint after 1.5 s without
/// scrolling), shown only if the list has more than [minItems] items. A drag
/// that **starts on the handle** opens a column "# A-Z" with a dock-like
/// magnifier and a bubble of the current letter; the list follows in real time
/// through [onLetterSelected]. A plain scroll or a swipe from the screen edge
/// never opens it. Touching the handle without dragging opens a grid of
/// letters, the alternative for one hand and for TalkBack.
///
/// @implements FR-010
class AlphabetScroller extends StatefulWidget {
  const new({
    required this.child,
    required this.letters,
    required this.itemCount,
    required this.onLetterSelected,
    required this.countLabel,
    required this.letterSemantics,
    required this.gridTitle,
    this.alignStart = false,
    this.minItems = 100,
    this.onHandleRect,
    super.key,
  });

  /// The list the index belongs to.
  final Widget child;
  final List<AlphabetLetter> letters;
  final int itemCount;

  /// Called with each letter reached; the host moves its list to it.
  final ValueChanged<String> onLetterSelected;

  /// "148 pistes", shown in the bubble.
  final String Function(int count) countLabel;

  /// "Lettre C, 148 pistes", read by TalkBack.
  final String Function(String letter, int count) letterSemantics;

  /// Title of the grid, and label of the handle.
  final String gridTitle;

  /// Handle and column on the start side (the "left hand" setting).
  final bool alignStart;
  final int minItems;

  /// The handle's rectangle in logical window pixels, for the native
  /// system-gesture exclusion (ADR-010).
  final ValueChanged<Rect>? onHandleRect;

  @override
  State<AlphabetScroller> createState() => _AlphabetScrollerState();
}

class _AlphabetScrollerState extends State<AlphabetScroller> {
  static const _magnifier = AlphabetMagnifier(
    base: TsSize.indexLetterBase,
    max: TsSize.indexLetterMax,
    shiftMax: TsSize.indexShiftMax,
    influence: TsSize.indexInfluence,
  );

  final GlobalKey _handleKey = GlobalKey();
  Timer? _idleTimer;
  Timer? _hideTimer;
  bool _recentlyScrolled = false;
  bool _dragging = false;
  bool _columnShown = false;
  String? _current;
  double _fingerY = 0;
  Rect? _reportedRect;

  bool get _enabled =>
      widget.itemCount > widget.minItems &&
      widget.letters.any((l) => l.hasItems);

  @override
  void dispose() {
    _idleTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _idleTimer?.cancel();
      if (!_recentlyScrolled) setState(() => _recentlyScrolled = true);
      _idleTimer = Timer(TsMotion.handleIdleHide, () {
        if (mounted) setState(() => _recentlyScrolled = false);
      });
    }
    return false;
  }

  RenderBox get _box => context.findRenderObject()! as RenderBox;

  double get _columnTop => TsSpace.l;

  double get _columnHeight => _box.size.height - 2 * TsSpace.l;

  void _dragStart(DragStartDetails details) {
    _hideTimer?.cancel();
    setState(() {
      _dragging = true;
      _columnShown = true;
    });
    _dragTo(details.globalPosition);
  }

  void _dragTo(Offset global) {
    final dy = _box.globalToLocal(global).dy;
    final label = letterAt(widget.letters, dy - _columnTop, _columnHeight);
    setState(() {
      _fingerY = (dy - _columnTop).clamp(0, _columnHeight);
      if (label != null && label != _current) {
        _current = label;
        unawaited(HapticFeedback.selectionClick());
        widget.onLetterSelected(label);
      }
    });
  }

  void _dragEnd() {
    setState(() => _dragging = false);
    _hideTimer = Timer(TsMotion.indexHideDelay, () {
      if (mounted) setState(() => _columnShown = false);
    });
  }

  void _step(int delta) {
    final available = [
      for (final l in widget.letters)
        if (l.hasItems) l.label,
    ];
    if (available.isEmpty) return;
    final at = _current == null ? -1 : available.indexOf(_current!);
    final next = available[(at + delta).clamp(0, available.length - 1)];
    setState(() => _current = next);
    widget.onLetterSelected(next);
  }

  String? _valueAt(int delta) {
    final available = [
      for (final l in widget.letters)
        if (l.hasItems) l,
    ];
    if (available.isEmpty) return null;
    final at = _current == null
        ? -1
        : available.indexWhere((l) => l.label == _current);
    final letter = available[(at + delta).clamp(0, available.length - 1)];
    return widget.letterSemantics(letter.label, letter.count);
  }

  Future<void> _openGrid() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _LetterGrid(
        title: widget.gridTitle,
        letters: widget.letters,
        countLabel: widget.countLabel,
      ),
    );
    if (picked != null) {
      setState(() => _current = picked);
      widget.onLetterSelected(picked);
    }
  }

  void _reportHandle() {
    final callback = widget.onHandleRect;
    final context = _handleKey.currentContext;
    if (callback == null || context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect == _reportedRect) return;
    _reportedRect = rect;
    callback(rect);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportHandle());
    final scheme = Theme.of(context).colorScheme;
    final handleLit = _recentlyScrolled || _dragging;
    final alignment = widget.alignStart
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;
    // Semantics need a value as soon as they can be increased: before any
    // letter is chosen it says how many items there are.
    final stamp = _current == null
        ? widget.countLabel(widget.itemCount)
        : widget.letterSemantics(
            _current!,
            widget.letters.firstWhere((l) => l.label == _current).count,
          );
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Align(
          alignment: alignment,
          child: Semantics(
            label: widget.gridTitle,
            value: stamp,
            increasedValue: _valueAt(1),
            decreasedValue: _valueAt(-1),
            onIncrease: () => _step(1),
            onDecrease: () => _step(-1),
            onTap: _openGrid,
            excludeSemantics: true,
            child: GestureDetector(
              key: _handleKey,
              behavior: HitTestBehavior.opaque,
              onTap: _openGrid,
              onVerticalDragStart: _dragStart,
              onVerticalDragUpdate: (d) => _dragTo(d.globalPosition),
              onVerticalDragEnd: (_) => _dragEnd(),
              onVerticalDragCancel: _dragEnd,
              child: SizedBox(
                width: TsSize.indexHandleTouch.width,
                height: TsSize.indexHandleTouch.height,
                child: Align(
                  alignment: widget.alignStart
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: AnimatedOpacity(
                    opacity: handleLit ? 1 : 0.4,
                    duration: TsMotion.short,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(TsRadius.full),
                      ),
                      child: const SizedBox(
                        width: TsSize.indexHandleWidth,
                        height: TsSize.indexHandleHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_columnShown) ...[
          Positioned.fill(
            top: _columnTop,
            bottom: TsSpace.l,
            child: IgnorePointer(
              child: _Column(
                letters: widget.letters,
                current: _current,
                fingerY: _fingerY,
                alignStart: widget.alignStart,
                magnifier: _magnifier,
              ),
            ),
          ),
          if (_current != null)
            _Bubble(
              letter: _current!,
              count: widget.letters
                  .firstWhere((l) => l.label == _current)
                  .count,
              countLabel: widget.countLabel,
              y: _fingerY + _columnTop,
              alignStart: widget.alignStart,
            ),
        ],
      ],
    );
  }
}

/// The column "# A-Z" with the magnifier around the finger.
class _Column extends StatelessWidget {
  const new({
    required this.letters,
    required this.current,
    required this.fingerY,
    required this.alignStart,
    required this.magnifier,
  });

  final List<AlphabetLetter> letters;
  final String? current;
  final double fingerY;
  final bool alignStart;
  final AlphabetMagnifier magnifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TsColors.of(context);
    final text = Theme.of(context).textTheme.labelSmall;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxHeight / letters.length;
        final over = fingerY / slot - 0.5;
        return Align(
          alignment: alignStart
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TsSize.indexEdgeInset,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(TsRadius.l),
              ),
              child: SizedBox(
                width: TsSize.indexColumnWidth,
                child: Column(
                  children: [
                    for (var i = 0; i < letters.length; i++)
                      SizedBox(
                        height: slot,
                        child: _LetterCell(
                          label: letters[i].label,
                          style: text,
                          color: !letters[i].hasItems
                              ? colors.unavailable
                              : letters[i].label == current
                              ? scheme.primary
                              : scheme.onSurface,
                          bold: letters[i].label == current,
                          scale: magnifier.size(i - over) / magnifier.base,
                          shift: magnifier.shift(i - over),
                          alignStart: alignStart,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LetterCell extends StatelessWidget {
  const new({
    required this.label,
    required this.style,
    required this.color,
    required this.bold,
    required this.scale,
    required this.shift,
    required this.alignStart,
  });

  final String label;
  final TextStyle? style;
  final Color color;
  final bool bold;
  final double scale;
  final double shift;
  final bool alignStart;

  @override
  Widget build(BuildContext context) => Center(
    child: Transform.translate(
      // Inward: toward the list.
      offset: Offset(alignStart ? shift : -shift, 0),
      child: Transform.scale(
        scale: scale,
        child: Text(
          label,
          style: style?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// The bubble of the current letter, left of the finger.
class _Bubble extends StatelessWidget {
  const new({
    required this.letter,
    required this.count,
    required this.countLabel,
    required this.y,
    required this.alignStart,
  });

  final String letter;
  final int count;
  final String Function(int count) countLabel;
  final double y;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const gap = TsSize.indexColumnWidth + 2 * TsSize.indexEdgeInset + TsSpace.m;
    return Positioned(
      top: y - TsSize.indexBubble / 2,
      left: alignStart ? gap : null,
      right: alignStart ? null : gap,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: TsSize.indexBubble,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter,
                  style: text.displaySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1,
                  ),
                ),
                Text(
                  countLabel(count),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
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

/// The grid "Go to letter": six columns of 48 dp buttons.
class _LetterGrid extends StatelessWidget {
  const new({
    required this.title,
    required this.letters,
    required this.countLabel,
  });

  final String title;
  final List<AlphabetLetter> letters;
  final String Function(int count) countLabel;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TsSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TsSpace.m),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            mainAxisSpacing: TsSpace.xs,
            crossAxisSpacing: TsSpace.xs,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final letter in letters)
                Semantics(
                  label: letter.hasItems
                      ? '${letter.label}, ${countLabel(letter.count)}'
                      : letter.label,
                  child: TextButton(
                    onPressed: letter.hasItems
                        ? () => Navigator.of(context).pop(letter.label)
                        : null,
                    child: Text(letter.label),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
