import 'package:flutter/material.dart';

class InviteShareRelationFilterChips extends StatelessWidget {
  const InviteShareRelationFilterChips({
    super.key,
    required this.selectedReason,
    required this.availableReasons,
    required this.onSelectReason,
  });

  final String? selectedReason;
  final List<String> availableReasons;
  final ValueChanged<String?> onSelectReason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_ReasonChipData>[
      _ReasonChipData(label: 'Todos', reason: null),
      ...availableReasons.map(
        (reason) => _ReasonChipData(
          label: _labelForReason(reason),
          reason: reason,
        ),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.label),
                  selected: selectedReason == item.reason,
                  showCheckmark: false,
                  selectedColor: colorScheme.primaryContainer,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: selectedReason == item.reason
                        ? colorScheme.primary.withValues(alpha: 0.35)
                        : colorScheme.outlineVariant,
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selectedReason == item.reason
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                  onSelected: (_) => onSelectReason(item.reason),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _labelForReason(String reason) {
    switch (reason) {
      case 'contact_match':
        return 'Contatos';
      case 'favorite_by_you':
        return 'Favoritos';
      case 'favorited_you':
        return 'Favoritaram você';
      case 'friend':
        return 'Amigos';
      default:
        return reason;
    }
  }
}

class _ReasonChipData {
  _ReasonChipData({required this.label, required this.reason});

  final String label;
  final String? reason;
}
