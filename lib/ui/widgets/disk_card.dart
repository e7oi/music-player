import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

enum DiskStatus { connected, scanning, absent, needsAccess }

/// A removable disk and its state (FR-010, HANDOFF section 6). The caller
/// provides every text: the card holds no wording of its own.
///
/// - connected: positive chip;
/// - scanning: progress with a stop action;
/// - absent: neutral, nothing to do;
/// - needsAccess: amber chip, [explanation] and a renew button.
///
/// @implements FR-010
class DiskCard extends StatelessWidget {
  const new({
    required this.name,
    required this.summary,
    required this.status,
    required this.statusLabel,
    this.scanLabel,
    this.scanProgress,
    this.stopLabel,
    this.onStop,
    this.explanation,
    this.renewLabel,
    this.onRenew,
    this.children = const [],
    super.key,
  });

  final String name;

  /// For example "1 To · 2 dossiers · 812 pistes".
  final String summary;
  final DiskStatus status;
  final String statusLabel;

  /// Progress text while scanning, and its value (0 to 1, null if unknown).
  final String? scanLabel;
  final double? scanProgress;
  final String? stopLabel;
  final VoidCallback? onStop;

  /// Shown under the chip when access must be renewed.
  final String? explanation;
  final String? renewLabel;
  final VoidCallback? onRenew;

  /// Extra rows, for example the folders of the disk.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final needsAccess = status == DiskStatus.needsAccess;
    final absent = status == DiskStatus.absent;
    final (iconBackground, iconColor, icon) = switch (status) {
      DiskStatus.connected || DiskStatus.scanning => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.storage_rounded,
      ),
      DiskStatus.absent => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
        Icons.usb_off_rounded,
      ),
      DiskStatus.needsAccess => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.lock_rounded,
      ),
    };
    final (chipBackground, chipColor) = switch (status) {
      DiskStatus.connected || DiskStatus.scanning => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      DiskStatus.absent => (Colors.transparent, scheme.onSurfaceVariant),
      DiskStatus.needsAccess => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
    };
    return Semantics(
      container: true,
      label: '$name, $summary, $statusLabel',
      child: Card(
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(TsSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(TsRadius.m),
                    ),
                    child: SizedBox.square(
                      dimension: TsSize.coverSmall,
                      child: Icon(icon, color: iconColor),
                    ),
                  ),
                  const SizedBox(width: TsSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleMedium),
                        Text(
                          summary,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TsSpace.m),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(TsRadius.full),
                  border: absent ? Border.all(color: scheme.outline) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TsSpace.m,
                    vertical: TsSpace.xs,
                  ),
                  child: Text(
                    statusLabel,
                    style: text.labelLarge?.copyWith(color: chipColor),
                  ),
                ),
              ),
              if (status == DiskStatus.scanning) ...[
                const SizedBox(height: TsSpace.m),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scanLabel ?? '',
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (stopLabel != null)
                      TextButton(onPressed: onStop, child: Text(stopLabel!)),
                  ],
                ),
                LinearProgressIndicator(value: scanProgress),
              ],
              if (needsAccess && explanation != null) ...[
                const SizedBox(height: TsSpace.m),
                Text(
                  explanation!,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (needsAccess && renewLabel != null) ...[
                const SizedBox(height: TsSpace.m),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRenew,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.tertiary,
                      foregroundColor: scheme.onTertiary,
                    ),
                    child: Text(renewLabel!),
                  ),
                ),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
