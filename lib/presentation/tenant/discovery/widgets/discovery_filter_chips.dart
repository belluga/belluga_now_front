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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.label),
                  selected: selectedType == item.type,
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
