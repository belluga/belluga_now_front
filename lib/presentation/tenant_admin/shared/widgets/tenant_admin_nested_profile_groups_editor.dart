import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminNestedProfileGroupRename =
    void Function(String groupId, String label);

typedef TenantAdminNestedProfileGroupMove =
    void Function(String groupId, int delta);

typedef TenantAdminNestedProfileGroupSelectionChanged =
    void Function(String groupId, String profileId, bool selected);

typedef TenantAdminNestedProfileGroupReadbackPageLoader =
    Future<TenantAdminNestedGroupMemberPage> Function({
      required String groupId,
      String? cursor,
    });

typedef TenantAdminNestedProfileGroupBaselineHydrator =
    Future<void> Function(String groupId);

class TenantAdminNestedProfileGroupsEditor extends StatelessWidget {
  const TenantAdminNestedProfileGroupsEditor({
    super.key,
    required this.keyPrefix,
    required this.groups,
    required this.candidatesStreamValue,
    required this.profileTypes,
    required this.addButtonKey,
    required this.onAddGroup,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onSelectionChanged,
    this.title = 'Abas de contas vinculadas',
    this.selectorTitle = 'Perfis',
    this.emptyCandidatesText = 'Nenhum perfil disponivel.',
    this.emptySelectionText = 'Selecionar perfis',
    this.selectedCountLabel = 'perfil(is) selecionado(s)',
    this.searchLabelText = 'Buscar perfil',
    this.emptySearchText = 'Nenhum perfil encontrado.',
    this.onSearchChanged,
    this.onProfileTypeChanged,
    this.onOpenPicker,
    this.onLoadMore,
    this.loadSelectedReadbackPage,
    this.ensureSelectedBaselineHydrated,
    this.selectedProfileType,
    this.searchLoadingStreamValue,
    this.searchPageLoadingStreamValue,
    this.searchHasMoreStreamValue,
  });

  final String keyPrefix;
  final List<TenantAdminNestedProfileGroup> groups;
  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final List<TenantAdminProfileTypeDefinition> profileTypes;
  final Key addButtonKey;
  final VoidCallback onAddGroup;
  final TenantAdminNestedProfileGroupRename onRenameGroup;
  final TenantAdminNestedProfileGroupMove onMoveGroup;
  final ValueChanged<String> onRemoveGroup;
  final TenantAdminNestedProfileGroupSelectionChanged onSelectionChanged;
  final String title;
  final String selectorTitle;
  final String emptyCandidatesText;
  final String emptySelectionText;
  final String selectedCountLabel;
  final String searchLabelText;
  final String emptySearchText;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onProfileTypeChanged;
  final Future<void> Function()? onOpenPicker;
  final Future<void> Function()? onLoadMore;
  final TenantAdminNestedProfileGroupReadbackPageLoader?
  loadSelectedReadbackPage;
  final TenantAdminNestedProfileGroupBaselineHydrator?
  ensureSelectedBaselineHydrated;
  final String? selectedProfileType;
  final StreamValue<bool>? searchLoadingStreamValue;
  final StreamValue<bool>? searchPageLoadingStreamValue;
  final StreamValue<bool>? searchHasMoreStreamValue;

  @override
  Widget build(BuildContext context) {
    return TenantAdminFormSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            _TenantAdminNestedProfileGroupEditor(
              keyPrefix: keyPrefix,
              group: groups[index],
              index: index,
              total: groups.length,
              candidatesStreamValue: candidatesStreamValue,
              profileTypes: profileTypes,
              onRenameGroup: onRenameGroup,
              onMoveGroup: onMoveGroup,
              onRemoveGroup: onRemoveGroup,
              onSelectionChanged: onSelectionChanged,
              selectorTitle: selectorTitle,
              emptyCandidatesText: emptyCandidatesText,
              emptySelectionText: emptySelectionText,
              selectedCountLabel: selectedCountLabel,
              searchLabelText: searchLabelText,
              emptySearchText: emptySearchText,
              onSearchChanged: onSearchChanged,
              onProfileTypeChanged: onProfileTypeChanged,
              onOpenPicker: onOpenPicker,
              onLoadMore: onLoadMore,
              loadSelectedReadbackPage: loadSelectedReadbackPage,
              ensureSelectedBaselineHydrated: ensureSelectedBaselineHydrated,
              selectedProfileType: selectedProfileType,
              searchLoadingStreamValue: searchLoadingStreamValue,
              searchPageLoadingStreamValue: searchPageLoadingStreamValue,
              searchHasMoreStreamValue: searchHasMoreStreamValue,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            key: addButtonKey,
            onPressed: groups.length >= 12 ? null : onAddGroup,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar grupo'),
          ),
        ],
      ),
    );
  }
}

class _TenantAdminNestedProfileGroupEditor extends StatelessWidget {
  const _TenantAdminNestedProfileGroupEditor({
    required this.keyPrefix,
    required this.group,
    required this.index,
    required this.total,
    required this.candidatesStreamValue,
    required this.profileTypes,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onSelectionChanged,
    required this.selectorTitle,
    required this.emptyCandidatesText,
    required this.emptySelectionText,
    required this.selectedCountLabel,
    required this.searchLabelText,
    required this.emptySearchText,
    required this.onSearchChanged,
    required this.onProfileTypeChanged,
    required this.onOpenPicker,
    required this.onLoadMore,
    required this.loadSelectedReadbackPage,
    required this.ensureSelectedBaselineHydrated,
    required this.selectedProfileType,
    required this.searchLoadingStreamValue,
    required this.searchPageLoadingStreamValue,
    required this.searchHasMoreStreamValue,
  });

  final String keyPrefix;
  final TenantAdminNestedProfileGroup group;
  final int index;
  final int total;
  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final List<TenantAdminProfileTypeDefinition> profileTypes;
  final TenantAdminNestedProfileGroupRename onRenameGroup;
  final TenantAdminNestedProfileGroupMove onMoveGroup;
  final ValueChanged<String> onRemoveGroup;
  final TenantAdminNestedProfileGroupSelectionChanged onSelectionChanged;
  final String selectorTitle;
  final String emptyCandidatesText;
  final String emptySelectionText;
  final String selectedCountLabel;
  final String searchLabelText;
  final String emptySearchText;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onProfileTypeChanged;
  final Future<void> Function()? onOpenPicker;
  final Future<void> Function()? onLoadMore;
  final TenantAdminNestedProfileGroupReadbackPageLoader?
  loadSelectedReadbackPage;
  final TenantAdminNestedProfileGroupBaselineHydrator?
  ensureSelectedBaselineHydrated;
  final String? selectedProfileType;
  final StreamValue<bool>? searchLoadingStreamValue;
  final StreamValue<bool>? searchPageLoadingStreamValue;
  final StreamValue<bool>? searchHasMoreStreamValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label:
          'Grupo ${group.label}; ${group.accountProfileIdValues.length} item(s) selecionado(s)',
      child: Column(
        children: [
          Container(
            key: Key('${keyPrefix}NestedGroup_${group.id}'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: Key('${keyPrefix}NestedGroupLabel_${group.id}'),
                        initialValue: group.label,
                        decoration: const InputDecoration(
                          labelText: 'Nome da aba',
                        ),
                        onChanged: (value) => onRenameGroup(group.id, value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome da aba e obrigatorio.';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mover para cima',
                      onPressed: index == 0
                          ? null
                          : () => onMoveGroup(group.id, -1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Mover para baixo',
                      onPressed: index >= total - 1
                          ? null
                          : () => onMoveGroup(group.id, 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      tooltip: 'Remover grupo',
                      onPressed: () => onRemoveGroup(group.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  selectorTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                StreamValueBuilder<List<TenantAdminAccountProfile>>(
                  streamValue: candidatesStreamValue,
                  builder: (context, candidates) {
                    return _TenantAdminNestedAccountSelector(
                      keyPrefix: keyPrefix,
                      group: group,
                      candidatesStreamValue: candidatesStreamValue,
                      candidates: candidates,
                      profileTypes: profileTypes,
                      onSelectionChanged: onSelectionChanged,
                      emptyCandidatesText: emptyCandidatesText,
                      emptySelectionText: emptySelectionText,
                      selectedCountLabel: selectedCountLabel,
                      searchLabelText: searchLabelText,
                      emptySearchText: emptySearchText,
                      onSearchChanged: onSearchChanged,
                      onProfileTypeChanged: onProfileTypeChanged,
                      onOpenPicker: onOpenPicker,
                      onLoadMore: onLoadMore,
                      loadSelectedReadbackPage: loadSelectedReadbackPage,
                      ensureSelectedBaselineHydrated:
                          ensureSelectedBaselineHydrated,
                      selectedProfileType: selectedProfileType,
                      searchLoadingStreamValue: searchLoadingStreamValue,
                      searchPageLoadingStreamValue:
                          searchPageLoadingStreamValue,
                      searchHasMoreStreamValue: searchHasMoreStreamValue,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantAdminNestedAccountSelector extends StatefulWidget {
  const _TenantAdminNestedAccountSelector({
    required this.keyPrefix,
    required this.group,
    required this.candidatesStreamValue,
    required this.candidates,
    required this.profileTypes,
    required this.onSelectionChanged,
    required this.emptyCandidatesText,
    required this.emptySelectionText,
    required this.selectedCountLabel,
    required this.searchLabelText,
    required this.emptySearchText,
    required this.onSearchChanged,
    required this.onProfileTypeChanged,
    required this.onOpenPicker,
    required this.onLoadMore,
    required this.loadSelectedReadbackPage,
    required this.ensureSelectedBaselineHydrated,
    required this.selectedProfileType,
    required this.searchLoadingStreamValue,
    required this.searchPageLoadingStreamValue,
    required this.searchHasMoreStreamValue,
  });

  final String keyPrefix;
  final TenantAdminNestedProfileGroup group;
  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final List<TenantAdminAccountProfile> candidates;
  final List<TenantAdminProfileTypeDefinition> profileTypes;
  final TenantAdminNestedProfileGroupSelectionChanged onSelectionChanged;
  final String emptyCandidatesText;
  final String emptySelectionText;
  final String selectedCountLabel;
  final String searchLabelText;
  final String emptySearchText;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onProfileTypeChanged;
  final Future<void> Function()? onOpenPicker;
  final Future<void> Function()? onLoadMore;
  final TenantAdminNestedProfileGroupReadbackPageLoader?
  loadSelectedReadbackPage;
  final TenantAdminNestedProfileGroupBaselineHydrator?
  ensureSelectedBaselineHydrated;
  final String? selectedProfileType;
  final StreamValue<bool>? searchLoadingStreamValue;
  final StreamValue<bool>? searchPageLoadingStreamValue;
  final StreamValue<bool>? searchHasMoreStreamValue;

  @override
  State<_TenantAdminNestedAccountSelector> createState() =>
      _TenantAdminNestedAccountSelectorState();
}

class _TenantAdminNestedAccountSelectorState
    extends State<_TenantAdminNestedAccountSelector> {
  late Set<String> _selectedIds;
  List<TenantAdminAccountProfileSelectionSummary> _selectedReadbackItems =
      const <TenantAdminAccountProfileSelectionSummary>[];
  String? _selectedReadbackNextCursor;
  String? _selectedReadbackErrorMessage;
  bool _selectedReadbackLoading = false;
  bool _selectedReadbackLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = _idsFromGroup(widget.group);
    _primeSelectedReadbackIfNeeded();
  }

  @override
  void didUpdateWidget(_TenantAdminNestedAccountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIds = _idsFromGroup(widget.group);
    if (oldWidget.group.id != widget.group.id) {
      _selectedReadbackItems =
          const <TenantAdminAccountProfileSelectionSummary>[];
      _selectedReadbackNextCursor = null;
      _selectedReadbackErrorMessage = null;
      _selectedReadbackLoading = false;
      _selectedReadbackLoaded = false;
    }
    _primeSelectedReadbackIfNeeded();
  }

  Set<String> _idsFromGroup(TenantAdminNestedProfileGroup group) {
    return group.accountProfileIdValues.map((entry) => entry.value).toSet();
  }

  bool _shouldUseSelectedReadback() {
    return widget.loadSelectedReadbackPage != null &&
        widget.group.memberCount > 0;
  }

  void _primeSelectedReadbackIfNeeded() {
    if (!_shouldUseSelectedReadback() ||
        _selectedReadbackLoaded ||
        _selectedReadbackLoading) {
      return;
    }
    unawaited(_primeSelectedReadback());
  }

  Future<void> _primeSelectedReadback() async {
    await _loadSelectedReadbackPage();
  }

  Future<void> _ensureSelectedBaselineHydratedIfNeeded() async {
    final ensureSelectedBaselineHydrated =
        widget.ensureSelectedBaselineHydrated;
    if (ensureSelectedBaselineHydrated == null ||
        !_shouldUseSelectedReadback()) {
      return;
    }
    try {
      await ensureSelectedBaselineHydrated(widget.group.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedReadbackErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadSelectedReadbackPage({
    String? cursor,
    bool append = false,
  }) async {
    final loadSelectedReadbackPage = widget.loadSelectedReadbackPage;
    if (loadSelectedReadbackPage == null) {
      return;
    }
    setState(() {
      _selectedReadbackLoading = true;
      _selectedReadbackErrorMessage = null;
    });
    try {
      final page = await loadSelectedReadbackPage(
        groupId: widget.group.id,
        cursor: cursor,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedReadbackItems = append
            ? <TenantAdminAccountProfileSelectionSummary>[
                ..._selectedReadbackItems,
                ...page.items,
              ]
            : page.items;
        _selectedReadbackNextCursor = page.nextCursor;
        _selectedReadbackLoaded = true;
        _selectedReadbackLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedReadbackErrorMessage = error.toString();
        _selectedReadbackLoaded = false;
        _selectedReadbackLoading = false;
      });
    }
  }

  Future<void> _loadMoreSelectedReadback() async {
    final cursor = _selectedReadbackNextCursor;
    if (_selectedReadbackLoading || cursor == null || cursor.trim().isEmpty) {
      return;
    }
    await _loadSelectedReadbackPage(cursor: cursor, append: true);
  }

  Future<void> _toggleProfileId(String profileId, bool selected) async {
    if (!selected) {
      await _ensureSelectedBaselineHydratedIfNeeded();
    }
    setState(() {
      if (selected) {
        _selectedIds.add(profileId);
      } else {
        _selectedIds.remove(profileId);
        _selectedReadbackItems = _selectedReadbackItems
            .where((entry) => entry.id != profileId)
            .toList(growable: false);
      }
    });
    widget.onSelectionChanged(widget.group.id, profileId, selected);
  }

  List<_SelectedAccountChipEntry> _selectedChipEntries() {
    final entries = <_SelectedAccountChipEntry>[];
    final seen = <String>{};

    for (final entry in _selectedReadbackItems) {
      if (seen.add(entry.id)) {
        entries.add(
          _SelectedAccountChipEntry(
            id: entry.id,
            label: (entry.displayName?.trim().isNotEmpty ?? false)
                ? entry.displayName!.trim()
                : entry.id,
          ),
        );
      }
    }

    for (final profile in widget.candidates) {
      if (!_selectedIds.contains(profile.id) || !seen.add(profile.id)) {
        continue;
      }
      entries.add(
        _SelectedAccountChipEntry(
          id: profile.id,
          label: profile.displayName.trim().isEmpty
              ? profile.id
              : profile.displayName.trim(),
        ),
      );
    }

    return List<_SelectedAccountChipEntry>.unmodifiable(entries);
  }

  int _selectedCountForLabel() {
    if (_selectedIds.isNotEmpty) {
      return _selectedIds.length;
    }
    if (_shouldUseSelectedReadback()) {
      return widget.group.memberCount;
    }
    return 0;
  }

  Future<void> _openCanonicalPicker() async {
    await _ensureSelectedBaselineHydratedIfNeeded();
    final onOpenPicker = widget.onOpenPicker;
    if (onOpenPicker != null) {
      await onOpenPicker();
    }
    if (!mounted) {
      return;
    }
    await showTenantAdminAccountProfileMultiPicker(
      context: context,
      candidatesStreamValue: widget.candidatesStreamValue,
      isLoadingStreamValue: widget.searchLoadingStreamValue!,
      isPageLoadingStreamValue: widget.searchPageLoadingStreamValue!,
      hasMoreStreamValue: widget.searchHasMoreStreamValue!,
      loadNextPage: widget.onLoadMore ?? () async {},
      onSearchChanged: widget.onSearchChanged ?? (_) {},
      onProfileTypeChanged: widget.onProfileTypeChanged,
      profileTypes: widget.profileTypes,
      title: widget.selectedCountLabel,
      emptyMessage: widget.emptySearchText,
      selectedProfileIds: _selectedIds,
      selectedProfileType: widget.selectedProfileType,
      searchLabelText: widget.searchLabelText,
      searchFieldKey: Key(
        '${widget.keyPrefix}NestedAccountSearch_${widget.group.id}',
      ),
      typeFilterKey: Key(
        '${widget.keyPrefix}NestedAccountTypeFilter_${widget.group.id}',
      ),
      listKey: Key('${widget.keyPrefix}NestedAccountList_${widget.group.id}'),
      candidateKeyBuilder: (profile) => Key(
        '${widget.keyPrefix}NestedAccountCandidate_${widget.group.id}_${profile.id}',
      ),
      onSelectionChanged: _toggleProfileId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEntries = _selectedChipEntries();
    final hasCandidates = widget.candidates.isNotEmpty;
    final isLoading = widget.searchLoadingStreamValue?.value ?? false;
    final selectedCount = _selectedCountForLabel();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key(
                  '${widget.keyPrefix}NestedAccountSelector_${widget.group.id}',
                ),
                onPressed: _openCanonicalPicker,
                icon: const Icon(Icons.manage_search_outlined),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedCount == 0
                        ? widget.emptySelectionText
                        : '$selectedCount ${widget.selectedCountLabel}',
                  ),
                ),
              ),
            ),
            if (_selectedReadbackErrorMessage != null &&
                _selectedReadbackErrorMessage!.trim().isNotEmpty &&
                selectedEntries.isEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _selectedReadbackLoading
                      ? null
                      : _primeSelectedReadback,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ],
            if (!isLoading &&
                !hasCandidates &&
                selectedEntries.isEmpty &&
                !_selectedReadbackLoading) ...[
              const SizedBox(height: 8),
              Text(widget.emptyCandidatesText),
            ],
            if (_selectedReadbackLoading && selectedEntries.isEmpty) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
            if (selectedEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedEntries
                    .map(
                      (entry) => Semantics(
                        label: 'Perfil selecionado ${entry.label}',
                        button: true,
                        child: InputChip(
                          key: Key(
                            '${widget.keyPrefix}NestedAccountSelectedChip_${widget.group.id}_${entry.id}',
                          ),
                          label: Text(entry.label),
                          onDeleted: () =>
                              unawaited(_toggleProfileId(entry.id, false)),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (_selectedReadbackLoading && selectedEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (_selectedReadbackNextCursor != null &&
                _selectedReadbackNextCursor!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _selectedReadbackLoading
                      ? null
                      : _loadMoreSelectedReadback,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('mais'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SelectedAccountChipEntry {
  const _SelectedAccountChipEntry({required this.id, required this.label});

  final String id;
  final String label;
}
