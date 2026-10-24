import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// An icon button with two states, such as shuffle or repeat. The active
/// state shows as a colour and as a dot under the icon, so it never depends
/// on the colour alone (BR-007, rule 3); TalkBack hears [label], the state
/// word and that it is a toggle.
///
/// @implements FR-010
class ToggleIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.selected,
    required this.label,
    required this.stateLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final bool selected;

  /// What the button is, for example "Shuffle".
  final String label;

  /// The state in words, for example "on" or "all tracks".
  final String stateLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      value: stateLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onPressed,
          radius: TsSize.touchTarget / 2,
          child: SizedBox.square(
            dimension: TsSize.touchTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                if (selected)
                  PositionedDirectional(
                    bottom: TsSpace.s,
                    child: SizedBox.square(
                      dimension: TsSize.toggleDot,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
