import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:flutter/material.dart';

class RecipientChips extends StatelessWidget {
  const RecipientChips({
    super.key,
    required this.recipients,
    required this.selectedProfileIds,
    required this.onSelectionChanged,
  });

  final List<InviteableRecipient> recipients;
  final Set<String> selectedProfileIds;
  final void Function(String profileId, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return const Text('Sem contatos convidáveis no momento.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipients
          .map(
            (recipient) => FilterChip(
              label: Text(recipient.displayName),
              selected: selectedProfileIds.contains(
                recipient.receiverAccountProfileId,
              ),
              onSelected: (selected) => onSelectionChanged(
                recipient.receiverAccountProfileId,
                selected,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
