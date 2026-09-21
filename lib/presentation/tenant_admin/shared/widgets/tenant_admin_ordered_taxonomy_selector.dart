import 'package:flutter/material.dart';

class TenantAdminOrderedTaxonomySelector extends StatelessWidget {
  const TenantAdminOrderedTaxonomySelector({
    super.key,
    required this.selectedSlugs,
    required this.labelForSlug,
    required this.onMove,
  });

  final List<String> selectedSlugs;
  final String Function(String slug) labelForSlug;
  final void Function(int fromIndex, int toIndex) onMove;

  @override
  Widget build(BuildContext context) {
    if (selectedSlugs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Ordem de exibição',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < selectedSlugs.length; index++)
          ListTile(
            key: ValueKey<String>(
              'tenantAdminOrderedTaxonomy_${selectedSlugs[index]}',
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(labelForSlug(selectedSlugs[index])),
            subtitle: Text('Posição ${index + 1} de ${selectedSlugs.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Mover para cima',
                  onPressed: index == 0 ? null : () => onMove(index, index - 1),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: 'Mover para baixo',
                  onPressed: index == selectedSlugs.length - 1
                      ? null
                      : () => onMove(index, index + 1),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
