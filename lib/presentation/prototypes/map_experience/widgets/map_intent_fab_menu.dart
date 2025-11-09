import 'package:flutter/material.dart';

enum MapIntent {
  discover,
  contribute,
  social,
  travel,
}

class MapIntentFabMenu extends StatelessWidget {
  const MapIntentFabMenu({
    super.key,
    required this.expanded,
    required this.activeIntent,
    required this.onToggle,
    required this.onSelectIntent,
  });

  final bool expanded;
  final MapIntent activeIntent;
  final VoidCallback onToggle;
  final ValueChanged<MapIntent> onSelectIntent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[
      _IntentButton(
        label: 'Explorar',
        icon: Icons.auto_awesome,
        intent: MapIntent.discover,
        isActive: activeIntent == MapIntent.discover,
        color: scheme.primary,
        onTap: () => onSelectIntent(MapIntent.discover),
      ),
      _IntentButton(
        label: 'Contribuir',
        icon: Icons.volunteer_activism,
        intent: MapIntent.contribute,
        isActive: activeIntent == MapIntent.contribute,
        color: scheme.tertiary,
        onTap: () => onSelectIntent(MapIntent.contribute),
      ),
      _IntentButton(
        label: 'Social',
        icon: Icons.groups_2,
        intent: MapIntent.social,
        isActive: activeIntent == MapIntent.social,
        color: scheme.secondary,
        onTap: () => onSelectIntent(MapIntent.social),
      ),
      _IntentButton(
        label: 'Mover-se',
        icon: Icons.directions,
        intent: MapIntent.travel,
        isActive: activeIntent == MapIntent.travel,
        color: scheme.primaryContainer,
        onTap: () => onSelectIntent(MapIntent.travel),
        foregroundColor: scheme.onPrimaryContainer,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: ShapeDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          children.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: w)).toList(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton.large(
          heroTag: 'map-intent-fab-main',
          onPressed: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              expanded ? Icons.close : Icons.tune,
              key: ValueKey<bool>(expanded),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntentButton extends StatelessWidget {
  const _IntentButton({
    required this.label,
    required this.icon,
    required this.intent,
    required this.isActive,
    required this.color,
    required this.onTap,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final MapIntent intent;
  final bool isActive;
  final Color color;
  final Color? foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = isActive ? color : scheme.surface;
    final fgColor = isActive ? (foregroundColor ?? scheme.onPrimary) : scheme.onSurfaceVariant;
    final elevation = isActive ? 2.0 : 0.5;

    return SizedBox(
      width: 190,
      child: FilledButton.icon(
        key: ValueKey<MapIntent>(intent),
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: elevation,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
