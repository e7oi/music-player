import 'package:flutter/material.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/features/library/folder_choice_model.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';

/// FR-015: the folders that hold audio, with the summary and the button
/// under them. Also the empty state and the error of the folder list.
///
/// @implements FR-015
class FolderChoiceView extends StatefulWidget {
  const new({
    required this.choice,
    required this.onConfirm,
    required this.onAddFolder,
    required this.onReload,
    super.key,
  });

  final LibraryFolderChoice choice;
  final ValueChanged<Set<String>> onConfirm;
  final VoidCallback onAddFolder;

  /// "Actualiser": reads the folders again.
  final VoidCallback onReload;

  @override
  State<FolderChoiceView> createState() => _FolderChoiceViewState();
}

class _FolderChoiceViewState extends State<FolderChoiceView> {
  late final Set<String> _selected = {...widget.choice.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choice = widget.choice;
    final folders = choice.folders;
    final empty = !choice.loading && folders.isEmpty;
    final summary = FolderChoiceSummary.of(folders, _selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // FR-015.3: a state that lasts sits in the flow, above the list.
        if (choice.loading) ProgressBanner(label: l10n.libraryScanning),
        Padding(
          padding: const EdgeInsets.all(TsSpace.l),
          child: Text(l10n.foldersIntro),
        ),
        Expanded(
          child: empty
              ? _Empty(onAdd: widget.onAddFolder, onReload: widget.onReload)
              : ListView(
                  children: [
                    _Section(title: l10n.foldersSection),
                    if (choice.loading)
                      for (var i = 0; i < 5; i++) const _SkeletonRow()
                    else
                      for (final FolderSummary folder in folders)
                        CheckboxListTile(
                          value: _selected.contains(folder.path),
                          title: Text(
                            folder.path.isEmpty
                                ? l10n.foldersRoot
                                : folder.path,
                          ),
                          subtitle: Text(
                            l10n.folderAudioCount(folder.fileCount),
                          ),
                          onChanged: (checked) => setState(() {
                            if (checked ?? false) {
                              _selected.add(folder.path);
                            } else {
                              _selected.remove(folder.path);
                            }
                          }),
                        ),
                    ListTile(
                      leading: const Icon(Icons.add_rounded),
                      title: Text(l10n.foldersAdd),
                      onTap: widget.onAddFolder,
                    ),
                  ],
                ),
        ),
        _Bar(
          summary: summary,
          loading: choice.loading,
          empty: empty,
          label: choice.cancelable ? l10n.foldersConfirm : l10n.foldersContinue,
          // The first choice needs a folder; editing it later may empty it.
          enabled: !choice.loading && (choice.cancelable || !summary.none),
          onPressed: () => widget.onConfirm({..._selected}),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: TsSpace.screenMargin,
      vertical: TsSpace.s,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final fill = TsColors.of(context).coverPlaceholder;
    Widget bar(double width) => DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(TsRadius.xs),
      ),
      child: SizedBox(width: width, height: TsSpace.m),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: TsSize.trackRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TsSpace.s,
            children: [bar(TsSize.coverPanel), bar(TsSize.coverPanel / 2)],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const new({
    required this.summary,
    required this.loading,
    required this.empty,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final FolderChoiceSummary summary;
  final bool loading;
  final bool empty;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = empty
        ? l10n.foldersNothingToAdd
        : loading
        ? l10n.foldersCounting(summary.folders)
        : summary.none
        ? l10n.foldersNoneChecked
        : l10n.foldersSummary(summary.folders, summary.files);
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TsSpace.l),
          child: Row(
            spacing: TsSpace.l,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: summary.none && !loading && !empty
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: TsSize.touchTarget,
                child: FilledButton(
                  onPressed: enabled ? onPressed : null,
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.onAdd, required this.onReload});

  final VoidCallback onAdd;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: TsSpace.s,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: TsSize.coverPanel / 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Text(
              l10n.foldersEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(l10n.foldersEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: TsSpace.s),
            FilledButton(onPressed: onAdd, child: Text(l10n.foldersAdd)),
            OutlinedButton(
              onPressed: onReload,
              child: Text(l10n.libraryRefresh),
            ),
          ],
        ),
      ),
    );
  }
}

/// The folder list could not be read: the error stays in the flow with a
/// retry (FR-015.6).
class FolderLoadFailedView extends StatelessWidget {
  const new({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          kind: BannerKind.error,
          message: l10n.foldersReadFailed,
          actionLabel: l10n.libraryRetry,
          onAction: onRetry,
        ),
        Padding(
          padding: const EdgeInsets.all(TsSpace.l),
          child: Text(l10n.foldersIntro),
        ),
      ],
    );
  }
}
