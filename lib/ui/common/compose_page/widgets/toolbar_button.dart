part of '../compose_page.dart';

/// A reusable toolbar button that shows an active state when toggled on.
/// Active: filled accent-coloured rounded rect (matching the FAB colour) with
/// white icon/label on top — clear and unambiguous on any background.
/// Inactive: dim grey icon/label, transparent background.
class _ToolbarButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  /// Mutually-exclusive: supply [icon] OR [label].
  final IconData? icon;
  final String? label;

  const _ToolbarButton({
    required this.isActive,
    required this.onPressed,
    this.icon,
    this.label,
  }) : assert(
            icon != null || label != null, 'Provide either an icon or a label');

  /// Same green used for the FAB.
  static const _activeBackground = AppTheme.accentColor;
  static const _activeForeground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // Generous padding for a ≥ 44 pt touch target.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? _activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isActive ? _activeForeground : inactiveColor,
                )
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _activeForeground : inactiveColor,
                  ),
                ),
        ),
      ),
    );
  }
}
