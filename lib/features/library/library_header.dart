import 'package:flutter/material.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';

/// Title and disabled search button of the Tracks view (FR-011.1).
class LibraryTitleBar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: TsSpace.screenMargin,
        right: TsSpace.s,
      ),
      child: SizedBox(
        height: TsSize.touchTarget + TsSpace.s,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.navTracks,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.searchSoon,
              icon: const Icon(Icons.search_rounded),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Refresh, Folders and Disks, under the title (FR-011.2).
class LibraryActionChips extends StatelessWidget {
  const new({
    required this.busy,
    required this.absentDisks,
    required this.onRefresh,
    required this.onFolders,
    required this.onDisks,
    super.key,
  });

  /// An index runs: refresh and folders wait for it.
  final bool busy;

  /// Disks that are absent or need their access renewed.
  final int absentDisks;
  final VoidCallback onRefresh;
  final VoidCallback onFolders;
  final VoidCallback onDisks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
      child: Row(
        children: [
          _Chip(
            icon: Icons.refresh_rounded,
            label: l10n.libraryRefresh,
            onPressed: busy ? null : onRefresh,
          ),
          const SizedBox(width: TsSpace.xs),
          _Chip(
            icon: Icons.folder_outlined,
            label: l10n.libraryFolders,
            onPressed: busy ? null : onFolders,
          ),
          const SizedBox(width: TsSpace.xs),
          _Chip(
            icon: Icons.usb_rounded,
            label: l10n.chipDisks,
            onPressed: onDisks,
            badge: absentDisks == 0 ? null : l10n.disksAbsentBadge(absentDisks),
            badgeColors: (scheme.tertiaryContainer, scheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
    this.badgeColors,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? badge;
  final (Color, Color)? badgeColors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badgeColors = this.badgeColors;
    return ActionChip(
      // Tight padding: the three chips and the badge must fit a phone held
      // upright, with the longest French labels.
      padding: const EdgeInsets.symmetric(horizontal: TsSpace.xs),
      labelPadding: const EdgeInsets.symmetric(horizontal: TsSpace.xs),
      avatar: Icon(icon),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badge != null && badgeColors != null) ...[
            const SizedBox(width: TsSpace.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: badgeColors.$1,
                borderRadius: BorderRadius.circular(TsRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TsSpace.s,
                  vertical: TsSpace.xs,
                ),
                child: Text(
                  badge!,
                  style: text.labelSmall?.copyWith(color: badgeColors.$2),
                ),
              ),
            ),
          ],
        ],
      ),
      onPressed: onPressed,
    );
  }
}

/// The banner of unavailable sources (BR-008, rules 2 and 3).
class SourcesBanner extends StatelessWidget {
  const new({
    required this.banner,
    required this.onSee,
    required this.onDismiss,
    super.key,
  });

  final SourceBanner banner;
  final VoidCallback onSee;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatusBanner(
      kind: BannerKind.warning,
      message: bannerText(l10n, banner),
      actionLabel: l10n.bannerSee,
      onAction: onSee,
      dismissTooltip: l10n.bannerDismiss,
      onDismiss: onDismiss,
    );
  }
}

/// "12 tracks skipped: SSD missing", or the forms for several disks and for
/// a lost access (BR-008, rule 2).
String bannerText(AppLocalizations l10n, SourceBanner banner) {
  final disks = banner.disks;
  if (disks.length == 1) {
    final disk = disks.single;
    return disk.issue == DiskIssue.absent
        ? l10n.bannerAbsentOne(banner.tracks, disk.label)
        : l10n.bannerAccessOne(banner.tracks, disk.label);
  }
  return disks.every((d) => d.issue == DiskIssue.absent)
      ? l10n.bannerAbsentMany(banner.tracks, disks.length)
      : l10n.bannerOther(banner.tracks, disks.length);
}

/// "2 600 tracks · 12 unavailable" and the label of the sort (FR-011.5).
class LibraryCountRow extends StatelessWidget {
  const new({required this.text, this.showSort = true, super.key});

  final String text;
  final bool showSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TsSpace.screenMargin,
        vertical: TsSpace.s,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (showSort) Text(l10n.librarySortTitle, style: style),
        ],
      ),
    );
  }
}
