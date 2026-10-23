import 'package:flutter/material.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/tuneshell_logo.dart';

/// A full screen of the first launch: a scrolling body, then the buttons,
/// always reachable (FR-014.7, BR-007).
class _FullScreen extends StatelessWidget {
  const new({required this.body, required this.actions, this.top});

  final Widget body;
  final List<Widget> actions;
  final Widget? top;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(
        left: TsSpace.xl,
        right: TsSpace.xl,
        bottom: TsSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?top,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(child: body),
                ),
              ),
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(height: TsSpace.s),
            action,
          ],
        ],
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const new({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: TsSize.buttonLarge,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon),
      label: Text(label),
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const new({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget dot({required bool active}) => AnimatedContainer(
      duration: TsMotion.short,
      width: active ? TsSize.stepDotActive : TsSize.stepDot,
      height: TsSize.stepDot,
      decoration: BoxDecoration(
        color: active ? scheme.primary : scheme.outlineVariant,
        borderRadius: BorderRadius.circular(TsRadius.full),
      ),
    );
    return Semantics(
      label: l10n.stepOf(step, 2),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: TsSpace.s,
        children: [
          dot(active: step == 1),
          dot(active: step == 2),
        ],
      ),
    );
  }
}

/// The welcome, step 1 of 2 (FR-014.1).
class WelcomePage extends StatelessWidget {
  const new({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // The name is one word, drawn in two colours.
    final name = l10n.appTitle;
    const split = 4;
    Widget promise(IconData icon, String label) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: TsSpace.m,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(TsRadius.m),
          ),
          child: SizedBox.square(
            dimension: TsSize.touchTarget - TsSpace.s,
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: TsSpace.s),
            child: Text(label, style: text.bodyLarge),
          ),
        ),
      ],
    );
    return _FullScreen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TsSpace.xl,
        children: [
          const TuneShellLogo(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TsSpace.s,
            children: [
              Text(
                l10n.welcomeGreeting,
                style: text.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name.substring(0, split)),
                      TextSpan(
                        text: name.substring(split),
                        style: TextStyle(color: scheme.primary),
                      ),
                    ],
                  ),
                  style: text.displaySmall,
                ),
              ),
              Text(l10n.welcomeTagline, style: text.titleLarge),
            ],
          ),
          Column(
            spacing: TsSpace.l,
            children: [
              promise(Icons.folder_open_rounded, l10n.welcomePromiseRead),
              promise(Icons.shield_outlined, l10n.welcomePromiseNoAccount),
              promise(Icons.lock_outline_rounded, l10n.welcomePromiseNoData),
            ],
          ),
        ],
      ),
      actions: [
        const _StepIndicator(step: 1),
        _PrimaryButton(label: l10n.welcomeStart, onPressed: onStart),
        Text(
          l10n.welcomeFooter,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HeroTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TsRadius.xl + TsSpace.s),
      ),
      child: SizedBox.square(
        dimension: TsSize.heroTile,
        child: Icon(icon, size: TsSize.heroIcon, color: color),
      ),
    ),
  );
}

/// Why access is needed and the button that asks for it, step 2 of 2; with
/// [refused], the banner of a simple refusal (FR-014.2, FR-014.3).
class AccessExplanationPage extends StatelessWidget {
  const new({
    required this.refused,
    required this.onAllow,
    required this.onNotNow,
    super.key,
  });

  final bool refused;
  final VoidCallback onAllow;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget guarantee(String label) => Row(
      spacing: TsSpace.m,
      children: [
        Icon(Icons.check_rounded, color: scheme.primary),
        Expanded(child: Text(label, style: text.bodyLarge)),
      ],
    );
    return _FullScreen(
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: TsSize.touchTarget,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.stepOf(2, 2),
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (refused)
            StatusBanner(
              kind: BannerKind.warning,
              message: l10n.accessRefused,
              margin: EdgeInsets.zero,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TsSpace.xl,
        children: [
          _HeroTile(
            icon: Icons.folder_open_rounded,
            background: scheme.primaryContainer,
            color: scheme.onPrimaryContainer,
          ),
          Semantics(
            header: true,
            child: Text(l10n.accessTitle, style: text.headlineSmall),
          ),
          Text(
            l10n.accessBody,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Column(
            spacing: TsSpace.m,
            children: [
              guarantee(l10n.accessGuaranteeReadOnly),
              guarantee(l10n.accessGuaranteeLocal),
            ],
          ),
        ],
      ),
      actions: [
        _PrimaryButton(
          label: refused ? l10n.accessRetry : l10n.accessAllow,
          onPressed: onAllow,
        ),
        SizedBox(
          height: TsSize.touchTarget,
          child: TextButton(
            onPressed: onNotNow,
            child: Text(l10n.accessNotNow),
          ),
        ),
      ],
    );
  }
}

/// Android no longer shows its dialog (FR-014.5).
class AccessBlockedPage extends StatelessWidget {
  const new({
    required this.onOpenSettings,
    required this.onChooseFolder,
    super.key,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onChooseFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final steps = [
      l10n.blockedStepSettings,
      l10n.blockedStepPermissions,
      l10n.blockedStepMusic,
      l10n.blockedStepAllow,
    ];
    return _FullScreen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TsSpace.xl,
        children: [
          _HeroTile(
            icon: Icons.lock_outline_rounded,
            background: scheme.tertiaryContainer,
            color: scheme.onTertiaryContainer,
          ),
          Semantics(
            header: true,
            child: Text(l10n.blockedTitle, style: text.headlineSmall),
          ),
          Text(
            l10n.blockedBody,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: TsRadius.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(TsSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: TsSpace.s,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Text('${i + 1}. ${steps[i]}', style: text.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        _PrimaryButton(
          label: l10n.blockedOpenSettings,
          icon: Icons.open_in_new_rounded,
          onPressed: onOpenSettings,
        ),
        SizedBox(
          height: TsSize.touchTarget,
          child: OutlinedButton(
            onPressed: onChooseFolder,
            child: Text(l10n.blockedChooseFolder),
          ),
        ),
        Text(
          l10n.blockedNote,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The library when the user chose "not now" (FR-014.6).
class AccessDeclinedView extends StatelessWidget {
  const new({required this.onAllow, super.key});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TsSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: TsSpace.l,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: TsSize.coverPanel / 2,
                color: scheme.onSurfaceVariant,
              ),
              Text(
                l10n.declinedTitle,
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(l10n.declinedBody, textAlign: TextAlign.center),
              FilledButton(onPressed: onAllow, child: Text(l10n.accessAllow)),
            ],
          ),
        ),
      ),
    );
  }
}
