import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

enum BannerKind { error, warning, info }

/// A persistent state shown **in the flow**, above a list, never over it
/// (BR-007, rule 2). Announced once to TalkBack (live region).
///
/// @implements FR-010
class StatusBanner extends StatelessWidget {
  const new({
    required this.kind,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.dismissTooltip,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(
      horizontal: TsSpace.screenMargin,
      vertical: TsSpace.xs,
    ),
    super.key,
  }) : assert(
         onDismiss == null || dismissTooltip != null,
         'A close button needs a label',
       );

  final BannerKind kind;
  final String message;

  /// Defaults to an icon that fits [kind].
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Label of the close button (it is shown when [onDismiss] is set).
  final String? dismissTooltip;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, defaultIcon) = switch (kind) {
      BannerKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_rounded,
      ),
      BannerKind.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.warning_amber_rounded,
      ),
      BannerKind.info => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        Icons.info_outline_rounded,
      ),
    };
    return Padding(
      padding: margin,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: TsRadius.banner,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TsSize.bannerMin),
            child: Padding(
              padding: const EdgeInsets.only(left: TsSpace.l),
              child: Row(
                children: [
                  Icon(icon ?? defaultIcon, color: foreground),
                  const SizedBox(width: TsSpace.m),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: TsSpace.m),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(foregroundColor: foreground),
                      child: Text(actionLabel!),
                    ),
                  if (onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      tooltip: dismissTooltip,
                      color: foreground,
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const SizedBox(width: TsSpace.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
