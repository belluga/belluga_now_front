import 'package:flutter/material.dart';

class EventActionsRow extends StatelessWidget {
  const EventActionsRow({
    super.key,
    required this.onDetails,
    required this.onShare,
    this.onRoute,
  });

  final VoidCallback onDetails;
  final VoidCallback onShare;
  final VoidCallback? onRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final actions = <Widget>[
      Expanded(
        child: FilledButton.icon(
          onPressed: onDetails,
          icon: const Icon(Icons.info_outlined),
          label: const Text('Detalhes'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: onShare,
        icon: const Icon(Icons.share_outlined),
        tooltip: 'Compartilhar',
      ),
    ];

    if (onRoute != null) {
      actions.add(const SizedBox(width: 8));
      actions.add(
        IconButton(
          onPressed: onRoute,
          icon: const Icon(Icons.directions_outlined),
          tooltip: 'Traçar rota',
          color: scheme.primary,
        ),
      );
    }

    return Row(children: actions);
  }
}
