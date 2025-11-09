import 'dart:async';

import 'package:flutter/material.dart';

enum MapIntent {
  discover,
  contribute,
  social,
  travel,
  myLocation,
}

class MapIntentFabMenu extends StatefulWidget {
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
  State<MapIntentFabMenu> createState() => _MapIntentFabMenuState();
}

class _MapIntentFabMenuState extends State<MapIntentFabMenu> {
  static const _condenseDelay = Duration(seconds: 2);

  bool _condensed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _handleExpandedChange(widget.expanded);
  }

  @override
  void didUpdateWidget(covariant MapIntentFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _handleExpandedChange(widget.expanded);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleExpandedChange(bool expanded) {
    _timer?.cancel();
    if (expanded) {
      setState(() => _condensed = false);
      _timer = Timer(_condenseDelay, () {
        if (mounted && widget.expanded) {
          setState(() => _condensed = true);
        }
      });
    } else {
      setState(() => _condensed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttons = [
      _IntentButton(
        label: 'Explorar',
        icon: Icons.auto_awesome,
        intent: MapIntent.discover,
        isActive: widget.activeIntent == MapIntent.discover,
        color: scheme.primary,
        onTap: () => widget.onSelectIntent(MapIntent.discover),
        condensed: _condensed,
      ),
      _IntentButton(
        label: 'Contribuir',
        icon: Icons.volunteer_activism,
        intent: MapIntent.contribute,
        isActive: widget.activeIntent == MapIntent.contribute,
        color: scheme.tertiary,
        onTap: () => widget.onSelectIntent(MapIntent.contribute),
        condensed: _condensed,
      ),
      _IntentButton(
        label: 'Social',
        icon: Icons.groups_2,
        intent: MapIntent.social,
        isActive: widget.activeIntent == MapIntent.social,
        color: scheme.secondary,
        onTap: () => widget.onSelectIntent(MapIntent.social),
        condensed: _condensed,
      ),
      _IntentButton(
        label: 'Mover-se',
        icon: Icons.directions,
        intent: MapIntent.travel,
        isActive: widget.activeIntent == MapIntent.travel,
        color: scheme.primaryContainer,
        onTap: () => widget.onSelectIntent(MapIntent.travel),
        foregroundColor: scheme.onPrimaryContainer,
        condensed: _condensed,
      ),
      _IntentButton(
        label: 'Você está aqui',
        icon: Icons.my_location,
        intent: MapIntent.myLocation,
        isActive: widget.activeIntent == MapIntent.myLocation,
        color: scheme.secondaryContainer,
        onTap: () => widget.onSelectIntent(MapIntent.myLocation),
        condensed: _condensed,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: buttons
                      .map(
                        (button) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: button,
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          heroTag: 'map-intent-fab-main',
          onPressed: widget.onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              widget.expanded ? Icons.close : Icons.tune,
              key: ValueKey<bool>(widget.expanded),
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
    required this.condensed,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final MapIntent intent;
  final bool isActive;
  final Color color;
  final Color? foregroundColor;
  final VoidCallback onTap;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = isActive ? color : scheme.surface;
    final fgColor =
        isActive ? (foregroundColor ?? scheme.onPrimary) : scheme.onSurfaceVariant;
    final elevation = 0.5;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: condensed
          ? FloatingActionButton.small(
              key: ValueKey<String>('condensed-${intent.name}'),
              heroTag: 'intent-${intent.name}-condensed',
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: elevation,
              onPressed: onTap,
              child: Icon(icon),
            )
          : FloatingActionButton.extended(
              key: ValueKey<String>('expanded-${intent.name}'),
              heroTag: 'intent-${intent.name}-expanded',
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: elevation,
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
