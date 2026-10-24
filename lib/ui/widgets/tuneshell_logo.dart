import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The mark of TuneShell, simplified from `docs/design/brand/`: a half shell,
/// a half loudspeaker and a note at the centre. Drawn in code so that no
/// image dependency is needed (ADR-014). Decorative for TalkBack.
///
/// @implements FR-014
class TuneShellLogo extends StatelessWidget {
  const new({this.size = TsSize.logo, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = TsColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(
          background: dark ? colors.brandNight : scheme.primaryContainer,
          shell: dark ? colors.brandCyan : scheme.primary,
          waves: dark ? colors.brandMint : scheme.primary,
          note: dark ? colors.brandMint : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const new({
    required this.background,
    required this.shell,
    required this.waves,
    required this.note,
  });

  final Color background;
  final Color shell;
  final Color waves;
  final Color note;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 108;
    final center = Offset(54 * unit, 54 * unit);
    canvas.drawCircle(center, 54 * unit, Paint()..color = background);

    // The shell: a half ring on the left, cut in bands.
    final band = Paint()
      ..color = shell
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * unit;
    for (final radius in [27.0, 20.0, 13.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * unit),
        math.pi / 2,
        math.pi,
        false,
        band,
      );
    }

    // The loudspeaker: sound waves on the right.
    final wave = Paint()
      ..color = waves
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * unit;
    for (final radius in [29.0, 22.0, 15.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * unit),
        -math.pi / 2,
        math.pi,
        false,
        wave,
      );
    }

    // The core, with the note.
    canvas
      ..drawCircle(center, 10 * unit, Paint()..color = background)
      ..drawCircle(
        center,
        10 * unit,
        Paint()
          ..color = waves
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * unit,
      );
    // A quaver: head, stem and flag.
    final ink = Paint()..color = note;
    canvas
      ..drawCircle(center + Offset(-2.5 * unit, 3.5 * unit), 2.6 * unit, ink)
      ..drawRect(
        Rect.fromLTWH(
          center.dx - 0.6 * unit,
          center.dy - 5.5 * unit,
          1.6 * unit,
          9 * unit,
        ),
        ink,
      )
      ..drawPath(
        Path()
          ..moveTo(center.dx + 1 * unit, center.dy - 5.5 * unit)
          ..lineTo(center.dx + 5.5 * unit, center.dy - 4 * unit)
          ..lineTo(center.dx + 5.5 * unit, center.dy - 1.5 * unit)
          ..lineTo(center.dx + 1 * unit, center.dy - 3 * unit)
          ..close(),
        ink,
      );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.background != background ||
      old.shell != shell ||
      old.waves != waves ||
      old.note != note;
}
