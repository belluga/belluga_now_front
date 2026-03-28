import 'package:flutter/material.dart';

class DiscoveryFilterChips extends StatelessWidget {
  const DiscoveryFilterChips({
    super.key,
    required this.selectedType,
    required this.availableTypes,
    required this.onSelectType,
    required this.labelForType,
  });

  final String? selectedType;
  final List<String> availableTypes;
  final ValueChanged<String?> onSelectType;
  final String Function(String) labelForType;

  @override
  Widget build(BuildContext context) {
    final orderedTypes = availableTypes;
    final items = <_FilterChipData>[
      _FilterChipData(label: 'Todos', type: null),
      ...orderedTypes.map(_chipForType),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.label),
                  selected: selectedType == item.type,
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selectedType == item.type
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer,
                      ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  onSelected: (_) => onSelectType(item.type),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  _FilterChipData _chipForType(String type) {
    return _FilterChipData(label: labelForType(type), type: type);
  }
}

class _FilterChipData {
  _FilterChipData({required this.label, required this.type});
  final String label;
  final String? type;
}
