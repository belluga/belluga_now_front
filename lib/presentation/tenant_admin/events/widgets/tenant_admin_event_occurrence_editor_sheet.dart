import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_occurrence_editor_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_programming_item_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminEventDateTimePicker = Future<DateTime?> Function({
  required DateTime initialDateTime,
  required DateTime firstDate,
  required DateTime lastDate,
});

typedef TenantAdminEventRelatedProfilePicker
    = Future<TenantAdminAccountProfile?> Function({
  required Set<String> excludedProfileIds,
});

typedef TenantAdminEventModalCloser = Future<bool> Function<T>(
  BuildContext context, [
  T? result,
]);

Future<void> showTenantAdminEventOccurrenceEditorSheet({
  required BuildContext context,
  required TenantAdminEventsController controller,
  required String occurrenceKey,
  required String title,
  required List<TenantAdminAccountProfile> venues,
  required TenantAdminEventDateTimePicker pickDateTime,
  required TenantAdminEventRelatedProfilePicker pickRelatedAccountProfile,
  required TenantAdminEventModalCloser closeModalSheet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StreamValueBuilder(
      streamValue: controller.eventFormStateStreamValue,
      builder: (context, _) {
        final occurrence = controller.occurrenceForKey(occurrenceKey);
        if (occurrence == null) {
          return _MissingOccurrenceEditorSheet(
            closeModalSheet: closeModalSheet,
          );
        }
        return _TenantAdminEventOccurrenceEditorSheet(
          title: title,
          occurrenceKey: occurrenceKey,
          occurrence: occurrence,
          programmingItems:
              controller.programmingItemsForOccurrenceKey(occurrenceKey),
          controller: controller,
          venues: venues,
          pickDateTime: pickDateTime,
          pickRelatedAccountProfile: pickRelatedAccountProfile,
          closeModalSheet: closeModalSheet,
        );
      },
    ),
  );
}

Future<void> showTenantAdminEventProgrammingItemEditorSheet({
  required BuildContext context,
  required TenantAdminEventsController controller,
  required String occurrenceKey,
  required List<TenantAdminAccountProfile> venues,
  required TenantAdminEventRelatedProfilePicker pickRelatedAccountProfile,
  required TenantAdminEventModalCloser closeModalSheet,
  String? itemKey,
  TenantAdminEventProgrammingItem? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TenantAdminEventProgrammingItemEditorSheet(
      existing: existing,
      itemKey: itemKey,
      controller: controller,
      occurrenceKey: occurrenceKey,
      venues: venues,
      pickRelatedAccountProfile: pickRelatedAccountProfile,
      closeModalSheet: closeModalSheet,
    ),
  );
}

class _MissingOccurrenceEditorSheet extends StatelessWidget {
  const _MissingOccurrenceEditorSheet({
    required this.closeModalSheet,
  });

  final TenantAdminEventModalCloser closeModalSheet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Data não encontrada',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => unawaited(closeModalSheet(context)),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Esta data não está mais disponível para edição.'),
        ],
      ),
    );
  }
}

class _TenantAdminEventOccurrenceEditorSheet extends StatefulWidget {
  const _TenantAdminEventOccurrenceEditorSheet({
    required this.title,
    required this.occurrenceKey,
    required this.occurrence,
    required this.programmingItems,
    required this.controller,
    required this.venues,
    required this.pickDateTime,
    required this.pickRelatedAccountProfile,
    required this.closeModalSheet,
  });

  final String title;
  final String occurrenceKey;
  final TenantAdminEventOccurrence occurrence;
  final List<MapEntry<String, TenantAdminEventProgrammingItem>>
      programmingItems;
  final TenantAdminEventsController controller;
  final List<TenantAdminAccountProfile> venues;
  final TenantAdminEventDateTimePicker pickDateTime;
  final TenantAdminEventRelatedProfilePicker pickRelatedAccountProfile;
  final TenantAdminEventModalCloser closeModalSheet;

  @override
  State<_TenantAdminEventOccurrenceEditorSheet> createState() =>
      _TenantAdminEventOccurrenceEditorSheetState();
}

class _TenantAdminEventOccurrenceEditorSheetState
    extends State<_TenantAdminEventOccurrenceEditorSheet> {
  String? _errorMessage;

  Future<void> _pickStart() async {
    final picked = await widget.pickDateTime(
      initialDateTime: widget.occurrence.dateTimeStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      widget.controller.updateOccurrenceStart(widget.occurrenceKey, picked);
      _errorMessage = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await widget.pickDateTime(
      initialDateTime:
          widget.occurrence.dateTimeEnd ?? widget.occurrence.dateTimeStart,
      firstDate: widget.occurrence.dateTimeStart,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      widget.controller.updateOccurrenceEnd(widget.occurrenceKey, picked);
      _errorMessage = null;
    });
  }

  Future<void> _addRelatedProfile() async {
    final selected = await widget.pickRelatedAccountProfile(
      excludedProfileIds: widget.occurrence.relatedAccountProfileIds
          .map((profileId) => profileId.value)
          .toSet(),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      widget.controller.addOccurrenceRelatedProfile(
        widget.occurrenceKey,
        selected,
      );
      _errorMessage = null;
    });
  }

  Future<void> _addProgrammingItem() async {
    await showTenantAdminEventProgrammingItemEditorSheet(
      context: context,
      controller: widget.controller,
      occurrenceKey: widget.occurrenceKey,
      venues: widget.venues,
      pickRelatedAccountProfile: widget.pickRelatedAccountProfile,
      closeModalSheet: widget.closeModalSheet,
    );
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  Future<void> _editProgrammingItem({
    required String itemKey,
    required TenantAdminEventProgrammingItem item,
  }) async {
    await showTenantAdminEventProgrammingItemEditorSheet(
      context: context,
      controller: widget.controller,
      occurrenceKey: widget.occurrenceKey,
      venues: widget.venues,
      pickRelatedAccountProfile: widget.pickRelatedAccountProfile,
      closeModalSheet: widget.closeModalSheet,
      itemKey: itemKey,
      existing: item,
    );
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const Key('tenantAdminOccurrenceCloseButton'),
                tooltip: 'Fechar',
                onPressed: () => unawaited(widget.closeModalSheet(context)),
                icon: const Icon(Icons.close),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('tenantAdminOccurrenceStartField'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Início'),
              subtitle: Text(
                _formatOccurrenceDateTime(widget.occurrence.dateTimeStart),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickStart,
            ),
            ListTile(
              key: const Key('tenantAdminOccurrenceEndField'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('Fim'),
              subtitle: Text(
                widget.occurrence.dateTimeEnd == null
                    ? 'Sem fim definido'
                    : _formatOccurrenceDateTime(
                        widget.occurrence.dateTimeEnd!,
                      ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.occurrence.dateTimeEnd != null)
                    IconButton(
                      tooltip: 'Limpar fim',
                      onPressed: () {
                        setState(() {
                          widget.controller.updateOccurrenceEnd(
                            widget.occurrenceKey,
                            null,
                          );
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.edit_calendar_outlined),
                ],
              ),
              onTap: _pickEnd,
            ),
            const Divider(height: 28),
            Text(
              'Perfis próprios da ocorrência',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (widget.occurrence.relatedAccountProfileIds.isEmpty)
              Text(
                'Nenhum perfil próprio nesta data.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final profileId
                  in widget.occurrence.relatedAccountProfileIds)
                ListTile(
                  key: Key('tenantAdminOccurrenceProfile_${profileId.value}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    TenantAdminEventOccurrenceEditorDraft.profileDisplayName(
                      profileId.value,
                      widget.occurrence.relatedAccountProfiles,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover perfil da ocorrência',
                    onPressed: () {
                      setState(() {
                        widget.controller.removeOccurrenceRelatedProfile(
                          widget.occurrenceKey,
                          profileId.value,
                        );
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
            OutlinedButton.icon(
              key: const Key('tenantAdminOccurrenceAddProfileButton'),
              onPressed: _addRelatedProfile,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar perfil próprio'),
            ),
            const Divider(height: 28),
            Text(
              'Programação',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (widget.programmingItems.isEmpty)
              Text(
                'Nenhum item de programação nesta data.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (var itemIndex = 0;
                  itemIndex < widget.programmingItems.length;
                  itemIndex++)
                _ProgrammingItemListTile(
                  key: Key('tenantAdminOccurrenceProgrammingItem_$itemIndex'),
                  item: widget.programmingItems[itemIndex].value,
                  venues: widget.venues,
                  onTap: () => _editProgrammingItem(
                    itemKey: widget.programmingItems[itemIndex].key,
                    item: widget.programmingItems[itemIndex].value,
                  ),
                  onRemove: () {
                    setState(() {
                      widget.controller.removeOccurrenceProgrammingItem(
                        occurrenceKey: widget.occurrenceKey,
                        itemKey: widget.programmingItems[itemIndex].key,
                      );
                      _errorMessage = null;
                    });
                  },
                ),
            OutlinedButton.icon(
              key: const Key('tenantAdminOccurrenceAddProgrammingButton'),
              onPressed: _addProgrammingItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item de programação'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _TenantAdminEventProgrammingItemEditorSheet extends StatefulWidget {
  const _TenantAdminEventProgrammingItemEditorSheet({
    required this.existing,
    required this.itemKey,
    required this.controller,
    required this.occurrenceKey,
    required this.venues,
    required this.pickRelatedAccountProfile,
    required this.closeModalSheet,
  });

  final TenantAdminEventProgrammingItem? existing;
  final String? itemKey;
  final TenantAdminEventsController controller;
  final String occurrenceKey;
  final List<TenantAdminAccountProfile> venues;
  final TenantAdminEventRelatedProfilePicker pickRelatedAccountProfile;
  final TenantAdminEventModalCloser closeModalSheet;

  @override
  State<_TenantAdminEventProgrammingItemEditorSheet> createState() =>
      _TenantAdminEventProgrammingItemEditorSheetState();
}

class _TenantAdminEventProgrammingItemEditorSheetState
    extends State<_TenantAdminEventProgrammingItemEditorSheet> {
  late final TenantAdminEventProgrammingItemDraft _draft =
      TenantAdminEventProgrammingItemDraft(existing: widget.existing);
  String? _errorMessage;

  Future<void> _linkOccurrenceProfile() async {
    final selected = await _pickOccurrenceRelatedAccountProfile(
      excludedProfileIds:
          _draft.linkedProfileIds.map((profileId) => profileId.value).toSet(),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _draft.upsertLinkedProfile(selected);
      _errorMessage = null;
    });
  }

  Future<void> _addOccurrenceProfile() async {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final selected = await widget.pickRelatedAccountProfile(
      excludedProfileIds: occurrence?.relatedAccountProfileIds
              .map((profileId) => profileId.value)
              .toSet() ??
          const <String>{},
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      widget.controller.addOccurrenceRelatedProfile(
        widget.occurrenceKey,
        selected,
      );
      _draft.upsertLinkedProfile(selected);
      _errorMessage = null;
    });
  }

  Future<TenantAdminAccountProfile?> _pickOccurrenceRelatedAccountProfile({
    required Set<String> excludedProfileIds,
  }) {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final relatedProfiles = occurrence?.relatedAccountProfiles ??
        const <TenantAdminAccountProfile>[];
    final relatedProfileIds = occurrence?.relatedAccountProfileIds ??
        const <TenantAdminAccountProfileIdValue>[];
    final profilesById = <String, TenantAdminAccountProfile>{
      for (final profile in relatedProfiles) profile.id: profile,
    };
    final candidates = relatedProfileIds
        .map((profileId) => profilesById[profileId.value])
        .whereType<TenantAdminAccountProfile>()
        .where((profile) => !excludedProfileIds.contains(profile.id))
        .toList(growable: false);

    if (candidates.isEmpty) {
      return Future<TenantAdminAccountProfile?>.value();
    }

    return showModalBottomSheet<TenantAdminAccountProfile>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Perfis próprios da data'),
                subtitle: Text(
                  'Selecione um participante já vinculado a esta ocorrência.',
                ),
              ),
              for (final profile in candidates)
                ListTile(
                  key: Key(
                    'tenantAdminOccurrenceProgrammingCandidate_${profile.id}',
                  ),
                  leading: const Icon(Icons.person_outline),
                  title: Text(profile.displayName),
                  subtitle: Text(profile.slug ?? profile.id),
                  onTap: () => unawaited(
                    widget.closeModalSheet(context, profile),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final occurrenceRelatedProfiles = occurrence?.relatedAccountProfiles ??
        const <TenantAdminAccountProfile>[];
    final availableOccurrenceProfileIds = _draft.availableOccurrenceProfileIds(
      occurrenceRelatedProfiles,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null
                  ? 'Adicionar item de programação'
                  : 'Editar item de programação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('tenantAdminProgrammingTimeField'),
              initialValue: _draft.time,
              decoration: const InputDecoration(
                labelText: 'Horário',
                hintText: '13:00',
              ),
              keyboardType: TextInputType.datetime,
              onChanged: (value) {
                _draft.time = value;
                _errorMessage = null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('tenantAdminProgrammingTitleField'),
              initialValue: _draft.title,
              decoration: const InputDecoration(
                labelText: 'Título (opcional)',
              ),
              onChanged: (value) {
                _draft.title = value;
                _errorMessage = null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Perfis vinculados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'A programação só pode usar perfis próprios desta data.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_draft.linkedProfileIds.isEmpty)
              Text(
                'Nenhum perfil vinculado.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final profileId in _draft.linkedProfileIds)
                ListTile(
                  key: Key('tenantAdminProgrammingProfile_${profileId.value}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    TenantAdminEventOccurrenceEditorDraft.profileDisplayName(
                      profileId.value,
                      _draft.linkedProfiles,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover perfil vinculado',
                    onPressed: () {
                      setState(() {
                        _draft.removeLinkedProfile(profileId.value);
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  key: const Key(
                    'tenantAdminProgrammingLinkOccurrenceProfileButton',
                  ),
                  onPressed: availableOccurrenceProfileIds.isEmpty
                      ? null
                      : _linkOccurrenceProfile,
                  icon: const Icon(Icons.link),
                  label: const Text('Vincular perfil da data'),
                ),
                OutlinedButton.icon(
                  key: const Key(
                    'tenantAdminProgrammingAddOccurrenceProfileButton',
                  ),
                  onPressed: _addOccurrenceProfile,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Adicionar perfil à data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('tenantAdminProgrammingLocationProfileDropdown'),
              initialValue: _draft.selectedLocationProfileId,
              decoration: const InputDecoration(
                labelText: 'Local da programação (opcional)',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Sem local específico'),
                ),
                ...widget.venues.map(
                  (venue) => DropdownMenuItem<String>(
                    value: venue.id,
                    child: Text(venue.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _draft.selectedLocationProfileId =
                      value == null || value.isEmpty ? null : value;
                  _errorMessage = null;
                });
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => unawaited(widget.closeModalSheet(context)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('tenantAdminProgrammingSaveButton'),
                    onPressed: () {
                      final validationError = _draft.validate();
                      if (validationError != null) {
                        setState(() {
                          _errorMessage = validationError;
                        });
                        return;
                      }
                      final item = _draft.toProgrammingItem();
                      if (widget.itemKey == null) {
                        widget.controller.addOccurrenceProgrammingItem(
                          widget.occurrenceKey,
                          item,
                        );
                      } else {
                        widget.controller.updateOccurrenceProgrammingItem(
                          occurrenceKey: widget.occurrenceKey,
                          itemKey: widget.itemKey!,
                          item: item,
                        );
                      }
                      unawaited(
                        widget.closeModalSheet(context),
                      );
                    },
                    child: const Text('Salvar item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgrammingItemListTile extends StatelessWidget {
  const _ProgrammingItemListTile({
    super.key,
    required this.item,
    required this.venues,
    required this.onTap,
    required this.onRemove,
  });

  final TenantAdminEventProgrammingItem item;
  final List<TenantAdminAccountProfile> venues;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Text(item.time),
      title: Text(
        item.title ??
            TenantAdminEventOccurrenceEditorDraft.firstProgrammingProfileName(
              item,
            ) ??
            'Item sem título',
      ),
      subtitle: _buildProgrammingItemSubtitle(item, venues),
      trailing: IconButton(
        tooltip: 'Remover item de programação',
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    );
  }

  Widget _buildProgrammingItemSubtitle(
    TenantAdminEventProgrammingItem item,
    List<TenantAdminAccountProfile> venues,
  ) {
    final locationLabel =
        TenantAdminEventOccurrenceEditorDraft.programmingLocationDisplayName(
      item,
      venues,
    );
    final lines = <String>[
      '${item.accountProfileIds.length} perfil(is) vinculado(s)',
      if (locationLabel != null) 'Local: $locationLabel',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => Text(line, overflow: TextOverflow.ellipsis))
          .toList(growable: false),
    );
  }
}

String _formatOccurrenceDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
