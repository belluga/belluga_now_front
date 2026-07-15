import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_occurrence_editor_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_programming_item_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/widgets/tenant_admin_account_profile_location_picker_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/events/widgets/tenant_admin_programming_item_card.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_nested_profile_groups_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminEventDateTimePicker =
    Future<DateTime?> Function({
      required DateTime initialDateTime,
      required DateTime firstDate,
      required DateTime lastDate,
    });

typedef TenantAdminEventRelatedProfilePicker =
    Future<TenantAdminAccountProfile?> Function({
      required Set<String> excludedProfileIds,
    });

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
          programmingItems: controller.programmingItemsForOccurrenceKey(
            occurrenceKey,
          ),
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
  int? insertAt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TenantAdminEventProgrammingItemEditorSheet(
      existing: existing,
      itemKey: itemKey,
      insertAt: insertAt,
      controller: controller,
      occurrenceKey: occurrenceKey,
      venues: venues,
      pickRelatedAccountProfile: pickRelatedAccountProfile,
      closeModalSheet: closeModalSheet,
    ),
  );
}

class _MissingOccurrenceEditorSheet extends StatelessWidget {
  const _MissingOccurrenceEditorSheet({required this.closeModalSheet});

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

  List<TenantAdminAccountProfile> get _currentVenues {
    final liveVenues = widget.controller.venueCandidatesStreamValue.value;
    if (liveVenues.isNotEmpty) {
      return liveVenues;
    }
    return widget.venues;
  }

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

  Future<void> _addProgrammingItem({int? insertAt}) async {
    await showTenantAdminEventProgrammingItemEditorSheet(
      context: context,
      controller: widget.controller,
      occurrenceKey: widget.occurrenceKey,
      venues: widget.venues,
      pickRelatedAccountProfile: widget.pickRelatedAccountProfile,
      closeModalSheet: widget.closeModalSheet,
      insertAt: insertAt,
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

  Widget _buildOccurrenceTaxonomySection(BuildContext context) {
    return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
      streamValue: widget.controller.taxonomiesStreamValue,
      builder: (context, _) {
        final allowedTaxonomies = widget.controller
            .allowedTaxonomyDefinitionsForSelectedEventType();
        if (allowedTaxonomies.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamValueBuilder<
          Map<String, List<TenantAdminTaxonomyTermDefinition>>
        >(
          streamValue: widget.controller.taxonomyTermsBySlugStreamValue,
          builder: (context, termsByTaxonomy) {
            final visibleGroups = allowedTaxonomies
                .map(
                  (taxonomy) => (
                    taxonomy: taxonomy,
                    terms:
                        termsByTaxonomy[taxonomy.slug] ??
                        const <TenantAdminTaxonomyTermDefinition>[],
                  ),
                )
                .where((entry) => entry.terms.isNotEmpty)
                .toList(growable: false);
            if (visibleGroups.isEmpty) {
              return const SizedBox.shrink();
            }
            final selectedTerms = _selectedOccurrenceTaxonomyTerms(
              widget.occurrence,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 28),
                Text(
                  'Taxonomias da ocorrência',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quando informadas, substituem as taxonomias do evento nesta data.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final group in visibleGroups) ...[
                  Text(
                    group.taxonomy.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final term in group.terms)
                        FilterChip(
                          key: Key(
                            'tenantAdminOccurrenceTaxonomy_${group.taxonomy.slug}_${term.slug}',
                          ),
                          label: Text(term.name),
                          selected:
                              selectedTerms[group.taxonomy.slug]?.contains(
                                term.slug,
                              ) ??
                              false,
                          onSelected: (isSelected) {
                            setState(() {
                              widget.controller.toggleOccurrenceTaxonomyTerm(
                                occurrenceKey: widget.occurrenceKey,
                                taxonomySlug: group.taxonomy.slug,
                                termSlug: term.slug,
                                isSelected: isSelected,
                              );
                              _errorMessage = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Map<String, Set<String>> _selectedOccurrenceTaxonomyTerms(
    TenantAdminEventOccurrence occurrence,
  ) {
    final selectedTerms = <String, Set<String>>{};
    for (final term in occurrence.taxonomyTerms) {
      final taxonomySlug = term.type.trim();
      final termSlug = term.value.trim();
      if (taxonomySlug.isEmpty || termSlug.isEmpty) {
        continue;
      }
      selectedTerms.putIfAbsent(taxonomySlug, () => <String>{}).add(termSlug);
    }
    return selectedTerms;
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
                    : _formatOccurrenceDateTime(widget.occurrence.dateTimeEnd!),
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
            _buildOccurrenceTaxonomySection(context),
            const Divider(height: 28),
            TenantAdminNestedProfileGroupsEditor(
              keyPrefix: 'OccurrenceProfile',
              title: 'Abas de perfis próprios da ocorrência',
              selectorTitle: 'Perfis',
              emptyCandidatesText: 'Nenhum perfil disponivel.',
              emptySelectionText: 'Selecionar perfis',
              selectedCountLabel: 'perfil(is) selecionado(s)',
              searchLabelText: 'Buscar perfil',
              emptySearchText: 'Nenhum perfil encontrado.',
              groups: widget.occurrence.profileGroups,
              candidatesStreamValue:
                  widget.controller.relatedAccountProfileCandidatesStreamValue,
              onSearchChanged: (query) => unawaited(
                widget.controller
                    .searchRelatedAccountProfileCandidatesForNestedGroups(
                      query,
                    ),
              ),
              onLoadMore: widget
                  .controller
                  .loadNextRelatedAccountProfileCandidatesForNestedGroups,
              searchLoadingStreamValue: widget
                  .controller
                  .relatedAccountProfileSearchLoadingStreamValue,
              searchPageLoadingStreamValue: widget
                  .controller
                  .relatedAccountProfileSearchPageLoadingStreamValue,
              searchHasMoreStreamValue: widget
                  .controller
                  .relatedAccountProfileSearchHasMoreStreamValue,
              profileTypes: const [],
              addButtonKey: const Key('TenantAdminOccurrenceProfileGroupAdd'),
              onAddGroup: () => widget.controller.addOccurrenceProfileGroup(
                widget.occurrenceKey,
              ),
              onRenameGroup: (groupId, label) =>
                  widget.controller.renameOccurrenceProfileGroup(
                    occurrenceKey: widget.occurrenceKey,
                    groupId: groupId,
                    label: label,
                  ),
              onMoveGroup: (groupId, delta) =>
                  widget.controller.moveOccurrenceProfileGroup(
                    occurrenceKey: widget.occurrenceKey,
                    groupId: groupId,
                    delta: delta,
                  ),
              onRemoveGroup: (groupId) =>
                  widget.controller.removeOccurrenceProfileGroup(
                    occurrenceKey: widget.occurrenceKey,
                    groupId: groupId,
                  ),
              onSelectionChanged: (groupId, profileId, selected) =>
                  widget.controller.toggleOccurrenceProfileGroupMember(
                    occurrenceKey: widget.occurrenceKey,
                    groupId: groupId,
                    profileId: profileId,
                    selected: selected,
                  ),
            ),
            const Divider(height: 28),
            Text('Programação', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (widget.programmingItems.isEmpty)
              Text(
                'Nenhum item de programação nesta data.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              _buildProgrammingInsertionAction(0),
              ReorderableListView(
                shrinkWrap: true,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  if (oldIndex < 0 ||
                      oldIndex >= widget.programmingItems.length) {
                    return;
                  }
                  widget.controller.moveOccurrenceProgrammingItem(
                    occurrenceKey: widget.occurrenceKey,
                    itemKey: widget.programmingItems[oldIndex].key,
                    targetIndex: newIndex,
                  );
                },
                children: [
                  for (
                    var itemIndex = 0;
                    itemIndex < widget.programmingItems.length;
                    itemIndex++
                  )
                    KeyedSubtree(
                      key: ValueKey(
                        'tenantAdminOccurrenceProgrammingReorderable_${widget.programmingItems[itemIndex].key}',
                      ),
                      child: Column(
                        children: [
                          TenantAdminProgrammingItemCard(
                            key: Key(
                              'tenantAdminOccurrenceProgrammingItem_$itemIndex',
                            ),
                            item: widget.programmingItems[itemIndex].value,
                            venues: _currentVenues,
                            dragHandle:
                                widget
                                    .programmingItems[itemIndex]
                                    .value
                                    .isSequential
                                ? ReorderableDragStartListener(
                                    key: Key(
                                      'tenantAdminOccurrenceProgrammingDrag_$itemIndex',
                                    ),
                                    index: itemIndex,
                                    child: const Tooltip(
                                      message: 'Reordenar item sequencial',
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  )
                                : null,
                            onTap: () => _editProgrammingItem(
                              itemKey: widget.programmingItems[itemIndex].key,
                              item: widget.programmingItems[itemIndex].value,
                            ),
                            onRemove: () {
                              setState(() {
                                widget.controller
                                    .removeOccurrenceProgrammingItem(
                                      occurrenceKey: widget.occurrenceKey,
                                      itemKey: widget
                                          .programmingItems[itemIndex]
                                          .key,
                                    );
                                _errorMessage = null;
                              });
                            },
                          ),
                          if (itemIndex + 1 < widget.programmingItems.length)
                            _buildProgrammingInsertionAction(itemIndex + 1),
                        ],
                      ),
                    ),
                ],
              ),
              _buildProgrammingInsertionAction(widget.programmingItems.length),
            ],
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

  Widget _buildProgrammingInsertionAction(int index) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: Key('tenantAdminOccurrenceProgrammingInsert_$index'),
        onPressed: () => _addProgrammingItem(insertAt: index),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Inserir item aqui'),
      ),
    );
  }
}

class _TenantAdminEventProgrammingItemEditorSheet extends StatefulWidget {
  const _TenantAdminEventProgrammingItemEditorSheet({
    required this.existing,
    required this.itemKey,
    required this.insertAt,
    required this.controller,
    required this.occurrenceKey,
    required this.venues,
    required this.pickRelatedAccountProfile,
    required this.closeModalSheet,
  });

  final TenantAdminEventProgrammingItem? existing;
  final String? itemKey;
  final int? insertAt;
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

  void _save(BuildContext context) {
    final validationError = _draft.validate();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }
    final item = _draft.toProgrammingItem();
    if (widget.itemKey == null) {
      final insertAt = widget.insertAt;
      if (insertAt == null) {
        widget.controller.addOccurrenceProgrammingItem(
          widget.occurrenceKey,
          item,
        );
      } else {
        widget.controller.insertOccurrenceProgrammingItem(
          occurrenceKey: widget.occurrenceKey,
          index: insertAt,
          item: item,
        );
      }
    } else {
      widget.controller.updateOccurrenceProgrammingItem(
        occurrenceKey: widget.occurrenceKey,
        itemKey: widget.itemKey!,
        item: item,
      );
    }
    unawaited(widget.closeModalSheet(context));
  }

  late final TextEditingController _timeController = TextEditingController(
    text: _draft.time,
  );
  late final TextEditingController _endTimeController = TextEditingController(
    text: _draft.endTime,
  );
  late final TextEditingController _titleController = TextEditingController(
    text: _draft.title,
  );
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _synchronizeDraftWithOccurrence();
    if (widget.existing == null && !_draft.isTimed) {
      _draft.setTimed(true);
    }
    _timeController.addListener(_syncTimeFromEditor);
    _endTimeController.addListener(_syncEndTimeFromEditor);
    _titleController.addListener(_syncTitleFromEditor);
  }

  @override
  void dispose() {
    _timeController.removeListener(_syncTimeFromEditor);
    _timeController.dispose();
    _endTimeController.removeListener(_syncEndTimeFromEditor);
    _endTimeController.dispose();
    _titleController.removeListener(_syncTitleFromEditor);
    _titleController.dispose();
    super.dispose();
  }

  void _syncTimeFromEditor() {
    if (_timeController.text.trim().isNotEmpty && !_draft.isTimed) {
      _draft.setTimed(true);
    }
    _draft.time = _timeController.text;
    _errorMessage = null;
  }

  void _syncEndTimeFromEditor() {
    if (_endTimeController.text.trim().isNotEmpty && !_draft.isTimed) {
      _draft.setTimed(true);
    }
    _draft.endTime = _endTimeController.text;
    _errorMessage = null;
  }

  void _syncTitleFromEditor() {
    _draft.title = _titleController.text;
    _errorMessage = null;
  }

  void _synchronizeDraftWithOccurrence() {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final allowedProfileIds =
        occurrence?.relatedAccountProfileIds
            .map((profileId) => profileId.value)
            .toSet() ??
        <String>{};

    _draft.linkedProfileIds.removeWhere(
      (profileId) => !allowedProfileIds.contains(profileId.value),
    );
    _draft.linkedProfiles.removeWhere(
      (profile) => !allowedProfileIds.contains(profile.id),
    );
  }

  List<TenantAdminAccountProfile> get _currentVenues {
    final liveVenues = widget.controller.venueCandidatesStreamValue.value;
    if (liveVenues.isNotEmpty) {
      return liveVenues;
    }
    return widget.venues;
  }

  String get _selectedLocationLabel {
    final selectedId = _draft.selectedLocationProfileId;
    if (selectedId == null || selectedId.isEmpty) {
      return 'Sem local específico';
    }
    final knownVenue = widget.controller.knownVenueCandidate(selectedId);
    if (knownVenue != null) {
      return knownVenue.displayName;
    }
    for (final venue in _currentVenues) {
      if (venue.id == selectedId) {
        return venue.displayName;
      }
    }
    return selectedId;
  }

  Future<void> _linkOccurrenceProfile() async {
    final selected = await _pickOccurrenceRelatedAccountProfile(
      excludedProfileIds: _draft.linkedProfileIds
          .map((profileId) => profileId.value)
          .toSet(),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _draft.upsertLinkedProfile(selected);
      _errorMessage = null;
    });
  }

  Future<void> _addOccurrenceProfile({required String groupId}) async {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final profileGroups =
        occurrence?.profileGroups ?? const <TenantAdminNestedProfileGroup>[];
    if (profileGroups.isEmpty) {
      setState(() {
        _errorMessage =
            'Crie uma aba de perfis próprios da ocorrência antes de adicionar perfis pela programação.';
      });
      return;
    }
    final selectedGroupId = profileGroups.any((group) => group.id == groupId)
        ? groupId
        : null;
    if (selectedGroupId == null) {
      setState(() {
        _errorMessage = 'Grupo da ocorrência inválido.';
      });
      return;
    }
    final selected = await widget.pickRelatedAccountProfile(
      excludedProfileIds:
          occurrence?.relatedAccountProfileIds
              .map((profileId) => profileId.value)
              .toSet() ??
          const <String>{},
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      widget.controller.addOccurrenceRelatedProfileToGroup(
        occurrenceKey: widget.occurrenceKey,
        groupId: selectedGroupId,
        profile: selected,
      );
      _draft.upsertLinkedProfile(selected);
      _errorMessage = null;
    });
  }

  Future<TenantAdminAccountProfile?> _pickOccurrenceRelatedAccountProfile({
    required Set<String> excludedProfileIds,
  }) {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final relatedProfiles =
        occurrence?.relatedAccountProfiles ??
        const <TenantAdminAccountProfile>[];
    final relatedProfileIds =
        occurrence?.relatedAccountProfileIds ??
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
                  onTap: () =>
                      unawaited(widget.closeModalSheet(context, profile)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProgrammingLocation() async {
    await widget.controller.preparePhysicalHostAccountProfilePicker();
    if (!mounted) {
      return;
    }

    final selected = await showTenantAdminAccountProfileLocationPickerSheet(
      context: context,
      controller: widget.controller,
      selectedLocationProfileId: _draft.selectedLocationProfileId,
      title: 'Local da programação',
      subtitle: 'Selecione um local específico para este item de programação.',
      keyPrefix: 'tenantAdminProgrammingLocation',
      closeModalSheet: widget.closeModalSheet,
      selectedLocationFallbackLabel: _selectedLocationLabel,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _draft.selectedLocationProfileId = selected.isEmpty ? null : selected;
      _draft.selectedLocationProfile = selected.isEmpty
          ? null
          : widget.controller.knownVenueCandidate(selected);
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.controller.occurrenceForKey(widget.occurrenceKey);
    final occurrenceRelatedProfiles =
        occurrence?.relatedAccountProfiles ??
        const <TenantAdminAccountProfile>[];
    final occurrenceProfileGroups =
        occurrence?.profileGroups ?? const <TenantAdminNestedProfileGroup>[];
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Adicionar item de programação'
                        : 'Editar item de programação',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('tenantAdminProgrammingCloseButton'),
                  tooltip: 'Fechar',
                  onPressed: () => unawaited(widget.closeModalSheet(context)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              key: const Key('tenantAdminProgrammingTimedToggle'),
              contentPadding: EdgeInsets.zero,
              value: _draft.isTimed,
              title: const Text('Item com horário'),
              subtitle: Text(
                _draft.isTimed
                    ? 'Usa faixa de horário explícita.'
                    : 'Item sequencial sem horário.',
              ),
              onChanged: (value) {
                setState(() {
                  _draft.setTimed(value);
                  if (!value) {
                    _timeController.text = '';
                    _endTimeController.text = '';
                  }
                  _errorMessage = null;
                });
              },
            ),
            if (_draft.isTimed) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tenantAdminProgrammingTimeField'),
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Horário inicial',
                  hintText: '13:00',
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tenantAdminProgrammingEndTimeField'),
                controller: _endTimeController,
                decoration: const InputDecoration(
                  labelText: 'Horário de fim (opcional)',
                  hintText: '18:00',
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
            const SizedBox(height: 12),
            TenantAdminRichTextEditor(
              key: const Key('tenantAdminProgrammingTitleEditor'),
              controller: _titleController,
              label: 'Título / copy do item',
              placeholder: 'Escreva o conteúdo do item de programação',
              minHeight: 220,
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
              ],
            ),
            if (occurrenceProfileGroups.isEmpty) ...[
              const SizedBox(height: 12),
              Tooltip(
                message:
                    'Crie uma aba de perfis próprios da ocorrência antes de adicionar perfis pela programação.',
                child: OutlinedButton.icon(
                  key: const Key(
                    'tenantAdminProgrammingAddOccurrenceProfileButton',
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Adicionar perfil à data'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                key: const Key(
                  'tenantAdminProgrammingAddOccurrenceProfileGroupRequiredText',
                ),
                'Crie uma aba de perfis próprios da ocorrência antes de adicionar perfis pela programação.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Adicionar perfil à data',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final group in occurrenceProfileGroups) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key(
                      'tenantAdminProgrammingAddOccurrenceProfileButton_${group.id}',
                    ),
                    onPressed: () => _addOccurrenceProfile(groupId: group.id),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(group.label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local da programação (opcional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  container: true,
                  button: true,
                  enabled: true,
                  identifier: 'tenant_admin_programming_location_trigger',
                  label: 'Local da programação',
                  value: _selectedLocationLabel,
                  onTap: _pickProgrammingLocation,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key(
                          'tenantAdminProgrammingLocationProfileDropdown',
                        ),
                        onPressed: _pickProgrammingLocation,
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(Icons.place_outlined),
                        label: Text(
                          _selectedLocationLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  child: Semantics(
                    container: true,
                    button: true,
                    enabled: true,
                    identifier: 'tenant_admin_programming_cancel_button',
                    label: 'Cancelar item',
                    onTap: () => unawaited(widget.closeModalSheet(context)),
                    child: ExcludeSemantics(
                      child: OutlinedButton(
                        onPressed: () =>
                            unawaited(widget.closeModalSheet(context)),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    enabled: true,
                    identifier: 'tenant_admin_programming_save_button',
                    label: 'Salvar item',
                    onTap: () => _save(context),
                    child: ExcludeSemantics(
                      child: FilledButton(
                        key: const Key('tenantAdminProgrammingSaveButton'),
                        onPressed: () => _save(context),
                        child: const Text('Salvar item'),
                      ),
                    ),
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

String _formatOccurrenceDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
