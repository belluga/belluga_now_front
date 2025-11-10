import 'package:flutter/material.dart';

class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.onSearch,
  });

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.map_outlined),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mapa • Guarapari',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar pontos',
              onPressed: onSearch,
            ),
          ],
        ),
      ),
    );
  }
}
