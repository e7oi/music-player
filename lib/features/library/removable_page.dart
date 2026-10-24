import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/library/removable_messages.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// Removable disks and their folders (UC-003). Temporary screen until the
/// MPL-016 mock-ups exist.
///
/// @implements UC-003
class RemovablePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RemovablePage> createState() => _RemovablePageState();
}

class _RemovablePageState extends ConsumerState<RemovablePage> {
  RemovableController get _controller =>
      ref.read(removableControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_controller.onResumed()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(removableControllerProvider);
    final reading = ref.watch(tagProgressProvider).value?.running ?? false;
    ref.listen(removableControllerProvider.select((s) => s.message), (
      _,
      message,
    ) {
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removableMessageText(l10n, message))),
      );
      _controller.clearMessage();
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.removableTitle)),
      body: Column(
        children: [
          if (state.busy || reading) const LinearProgressIndicator(),
          Expanded(
            child: state.disks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(TsSpace.xl),
                      child: Text(
                        l10n.removableNone,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final disk in state.disks)
                        _DiskTile(disk: disk, busy: state.busy),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(TsSpace.l),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () => unawaited(_controller.addFolder()),
                    child: Text(l10n.removableAddFolder),
                  ),
                ),
                if (state.busy || reading) ...[
                  const SizedBox(width: TsSpace.s),
                  OutlinedButton(
                    onPressed: () => unawaited(_controller.cancel()),
                    child: Text(l10n.removableCancel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiskTile extends ConsumerWidget {
  const new({required this.disk, required this.busy});

  final RemovableDisk disk;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(removableControllerProvider.notifier);
    final status = switch (disk.status) {
      RemovableStatus.available => l10n.removableAvailable,
      RemovableStatus.absent => l10n.removableAbsent,
      RemovableStatus.accessLost => l10n.removableAccessLost,
    };
    final folders = disk.folders.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.usb),
          title: Text(disk.disk.label),
          subtitle: Text(status),
          trailing: disk.status == RemovableStatus.accessLost
              ? TextButton(
                  onPressed: busy
                      ? null
                      : () => unawaited(controller.addFolder()),
                  child: Text(l10n.removableRenew),
                )
              : null,
        ),
        for (final folder in folders)
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: TsSpace.xxxl + TsSpace.xl,
              right: TsSpace.s,
            ),
            title: Text(folder.isEmpty ? l10n.removableRootFolder : folder),
            trailing: IconButton(
              tooltip: l10n.removableRemoveFolder,
              icon: const Icon(Icons.delete_outline),
              // Removing needs the disk: its tracks are found by a scan.
              onPressed: busy || disk.status != RemovableStatus.available
                  ? null
                  : () => unawaited(
                      controller.removeFolder(disk.disk.id, folder),
                    ),
            ),
          ),
        const Divider(),
      ],
    );
  }
}
