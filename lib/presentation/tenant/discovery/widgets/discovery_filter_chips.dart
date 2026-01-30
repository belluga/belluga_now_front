import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryFilterChips extends StatelessWidget {
  const DiscoveryFilterChips({
    super.key,
    required this.selectedTypeStream,
    required this.availableTypesStream,
    required this.onSelectType,
    required this.labelForType,
  });

  final StreamValue<String?> selectedTypeStream;
  final StreamValue<List<String>> availableTypesStream;
  final ValueChanged<String?> onSelectType;
  final String Function(String) labelForType;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<String>>(
      streamValue: availableTypesStream,
      builder: (context, availableTypes) {
        return StreamValueBuilder<String?>(
          streamValue: selectedTypeStream,
          builder: (context, selectedType) {
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
          },
        );
      },
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
