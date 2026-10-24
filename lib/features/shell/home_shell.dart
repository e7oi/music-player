import 'package:flutter/material.dart';
import 'package:tuneshell/features/shell/coming_soon_page.dart';
import 'package:tuneshell/features/shell/settings_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The four main views behind a navigation bar (narrow windows) or a rail
/// (600 dp and more), with the player bar kept above the navigation.
///
/// @implements FR-009
/// @implements UC-004
class HomeShell extends StatefulWidget {
  const new({
    required this.tracks,
    required this.playerBar,
    this.immersive = false,
    super.key,
  });

  /// The Tracks view: the library.
  final Widget tracks;

  /// Shown above the navigation in every view; empty when nothing plays.
  final Widget playerBar;

  /// The first-launch screens fill the window: no navigation and no player
  /// bar (FR-014.7). The views keep their state.
  final bool immersive;

  /// The background of the navigation rail (tests).
  static const railBackgroundKey = Key('rail-background');

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Not kept between two launches (FR-009.10).
  int _index = 0;

  /// Lets the views move between the bar and rail layouts on rotation without
  /// losing their state (FR-009.4).
  final GlobalKey _contentKey = GlobalKey();

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.music_note_rounded, l10n.navTracks),
      (Icons.album_rounded, l10n.navAlbums),
      (Icons.person_rounded, l10n.navArtists),
      (Icons.tune_rounded, l10n.navSettings),
    ];
    final content = KeyedSubtree(
      key: _contentKey,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                widget.tracks,
                ComingSoonPage(title: l10n.navAlbums),
                ComingSoonPage(title: l10n.navArtists),
                const SettingsPage(),
              ],
            ),
          ),
          if (!widget.immersive) widget.playerBar,
        ],
      ),
    );
    if (widget.immersive) return Scaffold(body: content);
    // FR-009.7: Back leads to Tracks before it leaves the application.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= TsSize.compactMax;
          if (wide) {
            return Scaffold(
              body: Row(
                children: [
                  // The background spans the whole edge, cut-out included; the
                  // items sit clear of the inset inside it.
                  ColoredBox(
                    key: HomeShell.railBackgroundKey,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: SafeArea(
                      right: false,
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final (icon, label) in destinations)
                            NavigationRailDestination(
                              icon: Icon(icon),
                              label: Text(label),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // The rail took the left inset: the views must not apply it
                  // again.
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeLeft: true,
                      child: content,
                    ),
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final (icon, label) in destinations)
                  NavigationDestination(icon: Icon(icon), label: label),
              ],
            ),
          );
        },
      ),
    );
  }
}
