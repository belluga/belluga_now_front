import 'package:flutter/material.dart';

class FilterTagSection extends StatelessWidget {
  const FilterTagSection({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.hasCategorySelection,
    required this.onToggle,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final bool hasCategorySelection;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (!hasCategorySelection || availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Subcategorias',
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in availableTags)
              FilterChip(
                label: Text(_formatTag(tag)),
                visualDensity: VisualDensity.compact,
                selected: selectedTags.contains(tag),
                onSelected: (_) => onToggle(tag),
              ),
          ],
        ),
      ],
    );
  }

  String _formatTag(String value) {
    if (value.length <= 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
