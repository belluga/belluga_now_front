import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryFilterChips extends StatelessWidget {
  const DiscoveryFilterChips({
    super.key,
    required this.selectedTypeStream,
    required this.availableTypesStream,
    required this.onSelectType,
  });

  final StreamValue<PartnerType?> selectedTypeStream;
  final StreamValue<List<PartnerType>> availableTypesStream;
  final ValueChanged<PartnerType?> onSelectType;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<PartnerType>>(
      streamValue: availableTypesStream,
      builder: (context, availableTypes) {
        return StreamValueBuilder<PartnerType?>(
          streamValue: selectedTypeStream,
          builder: (context, selectedType) {
            final orderedTypes = [
              PartnerType.artist,
              PartnerType.venue,
              PartnerType.experienceProvider,
              PartnerType.influencer,
              PartnerType.curator,
            ].where(availableTypes.contains).toList();
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

  _FilterChipData _chipForType(PartnerType type) {
    switch (type) {
      case PartnerType.artist:
        return _FilterChipData(label: 'Artistas', type: type);
      case PartnerType.venue:
        return _FilterChipData(label: 'Locais', type: type);
      case PartnerType.experienceProvider:
        return _FilterChipData(label: 'Experiências', type: type);
      case PartnerType.influencer:
        return _FilterChipData(label: 'Pessoas', type: type);
      case PartnerType.curator:
        return _FilterChipData(label: 'Curadores', type: type);
    }
  }
}

class _FilterChipData {
  _FilterChipData({required this.label, required this.type});
  final String label;
  final PartnerType? type;
}
