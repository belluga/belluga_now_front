import 'package:flutter/material.dart';

class PoiActionsRow extends StatelessWidget {
  const PoiActionsRow({
    super.key,
    required this.onDetails,
    required this.onShare,
    required this.onRoute,
  });

  final VoidCallback onDetails;
  final VoidCallback onShare;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onDetails,
            icon: const Icon(Icons.info_outlined),
            label: const Text('Ver Mais'),
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
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRoute,
          icon: const Icon(Icons.directions_outlined),
          tooltip: 'Tracar rota',
          color: scheme.primary,
        ),
      ],
    );
  }
}
