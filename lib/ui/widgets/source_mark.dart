import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

enum SourceMarkShape { circle, square, diamond, triangle, hexagon }

/// The mark of a source (HANDOFF section 4): a shape and a colour, so that two
/// sources differ even in greyscale. Decorative for TalkBack: the source
/// is named in the label of the row that carries it.
///
/// @implements FR-010
class SourceMark extends StatelessWidget {
  const new({
    required this.shape,
    required this.color,
    this.outlined = false,
    this.size = TsSize.sourceMark,
    super.key,
  });

  /// The mark of "Local": a neutral circle.
  factory local(TsColors colors, {double size = TsSize.sourceMark}) =>
      SourceMark(
        shape: SourceMarkShape.circle,
        color: colors.sourceLocal,
        size: size,
      );

  /// The mark of the disk at [index] (0 = first disk added): square,
  /// diamond, triangle, hexagon, then the same again as outlines.
  factory disk(int index, TsColors colors, {double size = TsSize.sourceMark}) =>
      SourceMark(
        shape: diskShapes[index % diskShapes.length],
        color: colors.sourceColor(index),
        outlined: TsColors.sourceOutlined(index),
        size: size,
      );

  static const List<SourceMarkShape> diskShapes = [
    SourceMarkShape.square,
    SourceMarkShape.diamond,
    SourceMarkShape.triangle,
    SourceMarkShape.hexagon,
  ];

  final SourceMarkShape shape;
  final Color color;

  /// The shape is drawn as an outline (5th disk and beyond).
  final bool outlined;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(shape, color, outlined: outlined),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const new(this.shape, this.color, {required this.outlined});

  final SourceMarkShape shape;
  final Color color;
  final bool outlined;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = outlined ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = size.shortestSide / 6
      ..isAntiAlias = true;
    final inset = outlined ? paint.strokeWidth / 2 : 0.0;
    final box = (Offset.zero & size).deflate(inset);
    final c = box.center;
    final r = box.shortestSide / 2;
    switch (shape) {
      case SourceMarkShape.circle:
        canvas.drawCircle(c, r, paint);
      case SourceMarkShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: c, radius: r * 0.88),
            Radius.circular(r * 0.2),
          ),
          paint,
        );
      case SourceMarkShape.diamond:
        canvas.drawPath(_polygon(c, r, 4, math.pi / 2), paint);
      case SourceMarkShape.triangle:
        canvas.drawPath(_polygon(c, r, 3, -math.pi / 2), paint);
      case SourceMarkShape.hexagon:
        canvas.drawPath(_polygon(c, r, 6, math.pi / 6), paint);
    }
  }

  static Path _polygon(Offset center, double radius, int sides, double start) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = start + i * 2 * math.pi / sides;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.shape != shape || old.color != color || old.outlined != outlined;
}
