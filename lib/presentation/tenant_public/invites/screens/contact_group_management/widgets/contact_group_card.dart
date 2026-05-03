import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:flutter/material.dart';

class ContactGroupCard extends StatelessWidget {
  const ContactGroupCard({
    super.key,
    required this.group,
    required this.saving,
    required this.onRename,
    required this.onEditMembers,
    required this.onDelete,
  });

  final InviteContactGroup group;
  final bool saving;
  final VoidCallback onRename;
  final VoidCallback onEditMembers;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(group.name),
        subtitle: Text('${group.recipientCount} contato(s)'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar membros',
              onPressed: saving ? null : onEditMembers,
              icon: const Icon(Icons.group),
            ),
            IconButton(
              tooltip: 'Renomear',
              onPressed: saving ? null : onRename,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: saving ? null : onDelete,
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}
