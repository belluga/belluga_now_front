import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryFilterChips extends StatelessWidget {
  const DiscoveryFilterChips({
    super.key,
    required this.selectedTypeStream,
    required this.onSelectType,
  });

  final StreamValue<PartnerType?> selectedTypeStream;
  final ValueChanged<PartnerType?> onSelectType;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<PartnerType?>(
      streamValue: selectedTypeStream,
      builder: (context, selectedType) {
        final items = <_FilterChipData>[
          _FilterChipData(label: 'Todos', type: null),
          _FilterChipData(label: 'Artistas', type: PartnerType.artist),
          _FilterChipData(label: 'Locais', type: PartnerType.venue),
          _FilterChipData(
            label: 'Experiências',
            type: PartnerType.experienceProvider,
          ),
          _FilterChipData(label: 'Pessoas', type: PartnerType.influencer),
          _FilterChipData(label: 'Curadores', type: PartnerType.curator),
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
  }
}

class _FilterChipData {
  _FilterChipData({required this.label, required this.type});
  final String label;
  final PartnerType? type;
}
