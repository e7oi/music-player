import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// A progress shown in the flow: determinate when [value] is set (0 to 1),
/// indeterminate otherwise. The caller updates it at most four times a second;
/// TalkBack reads the label only, not every step (FR-010).
///
/// @implements FR-010
class ProgressBanner extends StatelessWidget {
  const new({
    required this.label,
    this.value,
    this.margin = const EdgeInsets.symmetric(
      horizontal: TsSpace.screenMargin,
      vertical: TsSpace.xs,
    ),
    super.key,
  });

  final String label;
  final double? value;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: margin,
      child: Semantics(
        label: label,
        container: true,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: TsRadius.banner,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TsSpace.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: TsSpace.s),
                LinearProgressIndicator(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
