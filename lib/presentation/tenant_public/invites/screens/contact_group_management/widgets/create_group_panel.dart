import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/widgets/recipient_chips.dart';
import 'package:flutter/material.dart';

class CreateGroupPanel extends StatelessWidget {
  const CreateGroupPanel({
    super.key,
    required this.nameController,
    required this.recipients,
    required this.selectedProfileIds,
    required this.saving,
    required this.onSelectionChanged,
    required this.onCreate,
  });

  final TextEditingController nameController;
  final List<InviteableRecipient> recipients;
  final Set<String> selectedProfileIds;
  final bool saving;
  final void Function(String profileId, bool selected) onSelectionChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Novo grupo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        RecipientChips(
          recipients: recipients,
          selectedProfileIds: selectedProfileIds,
          onSelectionChanged: onSelectionChanged,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : onCreate,
          child: Text(saving ? 'Salvando...' : 'Criar grupo'),
        ),
      ],
    );
  }
}
