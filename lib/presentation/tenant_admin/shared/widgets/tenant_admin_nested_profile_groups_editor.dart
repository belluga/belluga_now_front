import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminNestedProfileGroupRename = void Function(
  String groupId,
  String label,
);

typedef TenantAdminNestedProfileGroupMove = void Function(
  String groupId,
  int delta,
);

typedef TenantAdminNestedProfileGroupSelectionChanged = void Function(
  String groupId,
  String profileId,
  bool selected,
);

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
    this.selectorTitle = 'Accounts',
    this.emptyCandidatesText = 'Nenhuma Account disponivel.',
    this.emptySelectionText = 'Selecionar Accounts',
    this.selectedCountLabel = 'Account(s) selecionada(s)',
    this.searchLabelText = 'Buscar Account',
    this.emptySearchText = 'Nenhuma Account encontrada.',
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
                        decoration:
                            const InputDecoration(labelText: 'Nome da aba'),
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
                      onPressed:
                          index == 0 ? null : () => onMoveGroup(group.id, -1),
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
                      candidates: candidates,
                      profileTypes: profileTypes,
                      onSelectionChanged: onSelectionChanged,
                      emptyCandidatesText: emptyCandidatesText,
                      emptySelectionText: emptySelectionText,
                      selectedCountLabel: selectedCountLabel,
                      searchLabelText: searchLabelText,
                      emptySearchText: emptySearchText,
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
    required this.candidates,
    required this.profileTypes,
    required this.onSelectionChanged,
    required this.emptyCandidatesText,
    required this.emptySelectionText,
    required this.selectedCountLabel,
    required this.searchLabelText,
    required this.emptySearchText,
  });

  final String keyPrefix;
  final TenantAdminNestedProfileGroup group;
  final List<TenantAdminAccountProfile> candidates;
  final List<TenantAdminProfileTypeDefinition> profileTypes;
  final TenantAdminNestedProfileGroupSelectionChanged onSelectionChanged;
  final String emptyCandidatesText;
  final String emptySelectionText;
  final String selectedCountLabel;
  final String searchLabelText;
  final String emptySearchText;

  @override
  State<_TenantAdminNestedAccountSelector> createState() =>
      _TenantAdminNestedAccountSelectorState();
}

class _TenantAdminNestedAccountSelectorState
    extends State<_TenantAdminNestedAccountSelector> {
  static const String _allTypes = '__all__';

  final MenuController _menuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = _allTypes;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = _idsFromGroup(widget.group);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(_TenantAdminNestedAccountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIds = _idsFromGroup(widget.group);
    if (_selectedType != _allTypes &&
        !widget.candidates
            .any((profile) => profile.profileType == _selectedType)) {
      _selectedType = _allTypes;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Set<String> _idsFromGroup(TenantAdminNestedProfileGroup group) {
    return group.accountProfileIdValues.map((entry) => entry.value).toSet();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _toggleProfile(TenantAdminAccountProfile profile, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(profile.id);
      } else {
        _selectedIds.remove(profile.id);
      }
    });
    widget.onSelectionChanged(widget.group.id, profile.id, selected);
  }

  Map<String, String> _profileTypeLabels() {
    return {
      for (final type in widget.profileTypes) type.type: type.label,
    };
  }

  String _profileTypeLabel(String profileType) {
    return _profileTypeLabels()[profileType] ?? profileType;
  }

  List<TenantAdminAccountProfile> _filteredCandidates() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.candidates.where((profile) {
      if (_selectedType != _allTypes && profile.profileType != _selectedType) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final typeLabel = _profileTypeLabel(profile.profileType).toLowerCase();
      return profile.displayName.toLowerCase().contains(query) ||
          profile.profileType.toLowerCase().contains(query) ||
          typeLabel.contains(query);
    }).toList(growable: false);
  }

  List<String> _candidateTypes() {
    final types = widget.candidates
        .map((profile) => profile.profileType)
        .toSet()
        .toList(growable: false);
    types.sort((left, right) =>
        _profileTypeLabel(left).compareTo(_profileTypeLabel(right)));
    return types;
  }

  List<TenantAdminAccountProfile> _selectedCandidates() {
    return widget.candidates
        .where((profile) => _selectedIds.contains(profile.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return Text(widget.emptyCandidatesText);
    }

    final selected = _selectedCandidates();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        final menuWidth = math.min(math.max(maxWidth, 320), 640).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuAnchor(
              controller: _menuController,
              menuChildren: [
                _buildMenu(context, menuWidth),
              ],
              builder: (context, controller, child) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key(
                      '${widget.keyPrefix}NestedAccountSelector_${widget.group.id}',
                    ),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
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
                );
              },
            ),
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
                          onDeleted: () => _toggleProfile(profile, false),
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

  Widget _buildMenu(BuildContext context, double menuWidth) {
    final types = _candidateTypes();
    final filtered = _filteredCandidates();

    return SizedBox(
      width: menuWidth,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: Key(
                '${widget.keyPrefix}NestedAccountSearch_${widget.group.id}',
              ),
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                labelText: widget.searchLabelText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: Key(
                '${widget.keyPrefix}NestedAccountTypeFilter_${widget.group.id}',
              ),
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de perfil',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: _allTypes,
                  child: Text('Todos os tipos'),
                ),
                for (final type in types)
                  DropdownMenuItem<String>(
                    value: type,
                    child: Text(_profileTypeLabel(type)),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value ?? _allTypes;
                });
              },
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(widget.emptySearchText),
                    )
                  : SingleChildScrollView(
                      primary: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: filtered.map((profile) {
                          final selected = _selectedIds.contains(profile.id);
                          return CheckboxListTile(
                            key: Key(
                              '${widget.keyPrefix}NestedAccountCandidate_${widget.group.id}_${profile.id}',
                            ),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: selected,
                            title: Text(profile.displayName),
                            subtitle:
                                Text(_profileTypeLabel(profile.profileType)),
                            onChanged: (value) =>
                                _toggleProfile(profile, value ?? false),
                          );
                        }).toList(growable: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
