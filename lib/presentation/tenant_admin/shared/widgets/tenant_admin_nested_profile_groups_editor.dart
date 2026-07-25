import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
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
    this.onLoadMore,
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
  final Future<void> Function()? onLoadMore;
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
              onLoadMore: onLoadMore,
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
    required this.onLoadMore,
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
  final Future<void> Function()? onLoadMore;
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
                      onLoadMore: onLoadMore,
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
    required this.onLoadMore,
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
  final Future<void> Function()? onLoadMore;
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

  @override
  void initState() {
    super.initState();
    _selectedIds = _idsFromGroup(widget.group);
  }

  @override
  void didUpdateWidget(_TenantAdminNestedAccountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIds = _idsFromGroup(widget.group);
  }

  Set<String> _idsFromGroup(TenantAdminNestedProfileGroup group) {
    return group.accountProfileIdValues.map((entry) => entry.value).toSet();
  }

  void _toggleProfileId(String profileId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(profileId);
      } else {
        _selectedIds.remove(profileId);
      }
    });
    widget.onSelectionChanged(widget.group.id, profileId, selected);
  }

  List<TenantAdminAccountProfile> _selectedCandidates() {
    return widget.candidates
        .where((profile) => _selectedIds.contains(profile.id))
        .toList(growable: false);
  }

  Future<void> _openCanonicalPicker() async {
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
      listKey: Key(
        '${widget.keyPrefix}NestedAccountList_${widget.group.id}',
      ),
      candidateKeyBuilder: (profile) => Key(
        '${widget.keyPrefix}NestedAccountCandidate_${widget.group.id}_${profile.id}',
      ),
      onSelectionChanged: _toggleProfileId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCandidates();
    final hasCandidates = widget.candidates.isNotEmpty;
    final isLoading = widget.searchLoadingStreamValue?.value ?? false;
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
                    _selectedIds.isEmpty
                        ? widget.emptySelectionText
                        : '${_selectedIds.length} ${widget.selectedCountLabel}',
                  ),
                ),
              ),
            ),
            if (!isLoading && !hasCandidates) ...[
              const SizedBox(height: 8),
              Text(widget.emptyCandidatesText),
            ],
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected
                    .map(
                      (profile) => Semantics(
                        label: 'Perfil selecionado ${profile.displayName}',
                        button: true,
                        child: InputChip(
                          key: Key(
                            '${widget.keyPrefix}NestedAccountSelectedChip_${widget.group.id}_${profile.id}',
                          ),
                          label: Text(profile.displayName),
                          onDeleted: () =>
                              _toggleProfileId(profile.id, false),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        );
      },
    );
  }
}
