import 'package:flutter/material.dart';
import 'package:tuneshell/ui/demo/index_demo_page.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';
import 'package:tuneshell/ui/widgets/disk_card.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// Every component in every state, in light and dark, for the owner to compare
/// with the mock-ups. Debug and profile builds only (ADR-010). The texts are
/// fictional sample data, not application strings.
///
/// @implements FR-010
class ComponentGallery extends StatefulWidget {
  const new({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  var _dark = false;

  @override
  Widget build(BuildContext context) {
    final theme = _dark ? TsTheme.dark() : TsTheme.light();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final colors = TsColors.of(context);
          final text = Theme.of(context).textTheme;
          Widget section(String title, List<Widget> children) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TsSpace.screenMargin,
                  TsSpace.xl,
                  TsSpace.screenMargin,
                  TsSpace.s,
                ),
                child: Text(title, style: text.titleLarge),
              ),
              ...children,
            ],
          );
          return Scaffold(
            appBar: AppBar(
              title: const Text('Component gallery'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: TsSpace.s),
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Light')),
                      ButtonSegment(value: true, label: Text('Dark')),
                    ],
                    selected: {_dark},
                    onSelectionChanged: (s) => setState(() => _dark = s.first),
                  ),
                ),
              ],
            ),
            body: ListView(
              children: [
                section('TrackTile', [
                  TrackTile(
                    title: 'Après la pluie',
                    artist: 'Clara Vey',
                    duration: '3:42',
                    mark: SourceMark.local(colors),
                  ),
                  TrackTile(
                    title: 'Aube sur le fleuve',
                    artist: 'Les Brumes',
                    duration: '4:18',
                    state: TrackTileState.playing,
                    mark: SourceMark.disk(0, colors),
                  ),
                  TrackTile(
                    title: '01 - piste sans titre.flac',
                    artist: 'Artiste inconnu',
                    duration: '2:12',
                    state: TrackTileState.noArtwork,
                    mark: SourceMark.disk(1, colors),
                  ),
                  TrackTile(
                    title: 'Auroral',
                    duration: '5:03',
                    state: TrackTileState.unavailable,
                    unavailableLabel: 'Nodal · non connecté',
                    mark: SourceMark.disk(2, colors),
                  ),
                  TrackTile(
                    title: 'Bastion',
                    duration: '3:30',
                    state: TrackTileState.unreadable,
                    unreadableLabel: 'Fichier illisible',
                    mark: SourceMark.disk(3, colors),
                  ),
                  const TrackTile(title: '', state: TrackTileState.loading),
                ]),
                section('SourceMark', [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TsSpace.screenMargin,
                    ),
                    child: Wrap(
                      spacing: TsSpace.l,
                      runSpacing: TsSpace.m,
                      children: [
                        SourceMark.local(colors, size: TsSpace.xl),
                        for (var i = 0; i < 8; i++)
                          SourceMark.disk(i, colors, size: TsSpace.xl),
                      ],
                    ),
                  ),
                ]),
                section('DiskCard', [
                  for (final status in DiskStatus.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TsSpace.screenMargin,
                      ).copyWith(bottom: TsSpace.m),
                      child: DiskCard(
                        name: 'SSD',
                        summary: '1 To · 2 dossiers · 812 pistes',
                        status: status,
                        statusLabel: switch (status) {
                          DiskStatus.connected ||
                          DiskStatus.scanning => 'Connecté',
                          DiskStatus.absent => 'Non connecté',
                          DiskStatus.needsAccess => 'Accès à renouveler',
                        },
                        scanLabel: 'Parcours : 1 240 / 3 100 fichiers',
                        scanProgress: 0.4,
                        stopLabel: 'Arrêter',
                        onStop: () {},
                        explanation:
                            "L'autorisation d'accès n'est plus valable.",
                        renewLabel: "Renouveler l'accès",
                        onRenew: () {},
                      ),
                    ),
                ]),
                section('StatusBanner and ProgressBanner', [
                  StatusBanner(
                    kind: BannerKind.error,
                    message: "Le dossier « Download » n'a pas pu être lu.",
                    actionLabel: 'Réessayer',
                    onAction: () {},
                    dismissTooltip: 'Fermer',
                    onDismiss: () {},
                  ),
                  StatusBanner(
                    kind: BannerKind.warning,
                    icon: Icons.usb_off_rounded,
                    message: '12 pistes ignorées : SSD absent',
                    actionLabel: 'Voir',
                    onAction: () {},
                    dismissTooltip: 'Fermer',
                    onDismiss: () {},
                  ),
                  StatusBanner(
                    kind: BannerKind.info,
                    message: 'Nouvelles pistes ajoutées : 24',
                    actionLabel: 'Afficher',
                    onAction: () {},
                    dismissTooltip: 'Fermer',
                    onDismiss: () {},
                  ),
                  const ProgressBanner(
                    label: 'Lecture des étiquettes : 340 / 2 600',
                    value: 340 / 2600,
                  ),
                  const ProgressBanner(
                    label: 'Recherche des fichiers audio… 1 120 trouvés',
                  ),
                ]),
                section('ArtworkTile', [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: TsSpace.screenMargin,
                    ),
                    child: Wrap(
                      spacing: TsSpace.l,
                      runSpacing: TsSpace.l,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        ArtworkTile(),
                        ArtworkTile(size: TsSize.coverPanel),
                        ArtworkTile(size: TsSize.coverDetail),
                        ArtworkTile(unavailable: true),
                      ],
                    ),
                  ),
                ]),
                section('JumpToCurrentFab', [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TsSpace.screenMargin,
                    ),
                    child: Wrap(
                      spacing: TsSpace.l,
                      runSpacing: TsSpace.l,
                      children: [
                        JumpToCurrentFab(label: 'En cours', onPressed: () {}),
                        JumpToCurrentFab(
                          label: 'En cours',
                          direction: JumpDirection.up,
                          folded: true,
                          onPressed: () {},
                        ),
                        JumpToCurrentFab(
                          label: 'Dernière jouée',
                          lastPlayed: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ]),
                section('AlphabetScroller', [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TsSpace.screenMargin,
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => IndexDemoPage(dark: _dark),
                        ),
                      ),
                      child: const Text('Open the 5,000-row list'),
                    ),
                  ),
                  const SizedBox(height: TsSpace.xxl),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
