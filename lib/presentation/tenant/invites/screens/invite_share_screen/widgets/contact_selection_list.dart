import 'dart:typed_data';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ContactSelectionList extends StatelessWidget {
  const ContactSelectionList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I.get<InviteShareScreenController>();

    return StreamValueBuilder<bool>(
      streamValue: controller.contactsPermissionGranted,
      builder: (context, permissionGranted) {
        if (!permissionGranted) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.contacts_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Acesso aos contatos necessário',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para convidar seus contatos, precisamos de acesso à sua agenda.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadContacts,
                  child: const Text('Permitir Acesso'),
                ),
              ],
            ),
          );
        }

        return StreamValueBuilder<List<ContactModel>>(
          streamValue: controller.contactsStreamValue,
          builder: (context, contacts) {
            if (contacts.isEmpty) {
              return const Center(child: Text('Nenhum contato encontrado'));
            }

            return StreamValueBuilder<List<ContactModel>>(
              streamValue: controller.selectedContactsStreamValue,
              builder: (context, selectedContacts) {
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = selectedContacts.contains(contact);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: contact.avatar != null
                            ? MemoryImage(Uint8List.fromList(contact.avatar!))
                            : null,
                        child: contact.avatar == null
                            ? Text(contact.displayName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.phones.first),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => controller.toggleContact(contact),
                      ),
                      onTap: () => controller.toggleContact(contact),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
