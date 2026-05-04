import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/controllers/contact_group_management_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/widgets/contact_group_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/widgets/create_group_panel.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/widgets/recipient_chips.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/widgets/rename_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ContactGroupManagementScreen extends StatefulWidget {
  const ContactGroupManagementScreen({super.key});

  @override
  State<ContactGroupManagementScreen> createState() =>
      _ContactGroupManagementScreenState();
}

class _ContactGroupManagementScreenState
    extends State<ContactGroupManagementScreen> {
  late final ContactGroupManagementController _controller =
      GetIt.I.get<ContactGroupManagementController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos de contatos'),
      ),
      body: SafeArea(
        child: StreamValueBuilder<List<InviteableRecipient>>(
          streamValue: _controller.inviteableRecipientsStreamValue,
          builder: (context, recipients) {
            return StreamValueBuilder<List<InviteContactGroup>>(
              streamValue: _controller.groupsStreamValue,
              builder: (context, groups) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.savingStreamValue,
                  builder: (context, saving) {
                    return StreamValueBuilder<Set<String>>(
                      streamValue:
                          _controller.selectedCreateProfileIdsStreamValue,
                      builder: (context, selectedProfileIds) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            CreateGroupPanel(
                              nameController:
                                  _controller.createGroupNameController,
                              recipients: recipients,
                              selectedProfileIds: selectedProfileIds,
                              saving: saving,
                              onSelectionChanged: (profileId, selected) {
                                _controller.toggleCreateProfileSelection(
                                  accountProfileId: profileId,
                                  selected: selected,
                                );
                              },
                              onCreate: _createGroup,
                            ),
                            const SizedBox(height: 20),
                            ...groups.map(
                              (group) => ContactGroupCard(
                                group: group,
                                saving: saving,
                                onRename: () => _renameGroup(context, group),
                                onEditMembers: () =>
                                    _editMembers(context, group, recipients),
                                onDelete: () => _deleteGroup(group),
                              ),
                            ),
                            if (groups.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  'Nenhum grupo criado.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = _controller.createGroupNameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    await _controller.createGroup(
      name: name,
      recipientAccountProfileIds: _controller
          .selectedCreateProfileIdsStreamValue.value
          .toList(growable: false),
    );
    if (!mounted) {
      return;
    }
    _controller.clearCreateDraft();
  }

  Future<void> _renameGroup(
    BuildContext context,
    InviteContactGroup group,
  ) async {
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) => RenameGroupDialog(initialName: group.name),
    );
    final normalized = nextName?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    await _controller.renameGroup(group: group, name: normalized);
  }

  Future<void> _editMembers(
    BuildContext context,
    InviteContactGroup group,
    List<InviteableRecipient> recipients,
  ) async {
    final selected = group.recipientAccountProfileIds.toSet();
    final nextSelection = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    RecipientChips(
                      recipients: recipients,
                      selectedProfileIds: selected,
                      onSelectionChanged: (profileId, isSelected) {
                        if (isSelected) {
                          selected.add(profileId);
                        } else {
                          selected.remove(profileId);
                        }
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _popCurrentRoute(context, selected),
                      child: const Text('Salvar membros'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (nextSelection == null) {
      return;
    }
    await _controller.updateGroupMembers(
      group: group,
      recipientAccountProfileIds: nextSelection.toList(growable: false),
    );
  }

  Future<void> _deleteGroup(InviteContactGroup group) {
    return _controller.deleteGroup(group);
  }

  void _popCurrentRoute<T>(BuildContext context, T value) {
    ModalRoute.of(context)?.navigator?.maybePop(value);
  }
}
