import 'package:flutter/material.dart';

class TagChips extends StatelessWidget {
  const TagChips({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClearTags,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final void Function(String tag) onTagToggled;
  final VoidCallback onClearTags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (selectedTags.isNotEmpty)
              FilterChip(
                label: const Text('Limpar tags'),
                selected: false,
                onSelected: (_) => onClearTags(),
              ),
            for (final tag in tags)
              FilterChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                onSelected: (_) => onTagToggled(tag),
              ),
          ],
        ),
      ],
    );
  }
}
