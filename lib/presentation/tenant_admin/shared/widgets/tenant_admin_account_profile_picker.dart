import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminAccountProfilePickerCandidateKeyBuilder =
    Key Function(TenantAdminAccountProfile profile);

Future<TenantAdminAccountProfile?> showTenantAdminAccountProfilePicker({
  required BuildContext context,
  required StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue,
  required StreamValue<bool> isLoadingStreamValue,
  required StreamValue<bool> isPageLoadingStreamValue,
  required StreamValue<bool> hasMoreStreamValue,
  StreamValue<String?>? errorStreamValue,
  required Future<void> Function() loadNextPage,
  required ValueChanged<String> onSearchChanged,
  required List<TenantAdminProfileTypeDefinition> profileTypes,
  required String title,
  required String emptyMessage,
  ValueChanged<String?>? onProfileTypeChanged,
  String? selectedProfileId,
  String? selectedProfileType,
  String initialSearchQuery = '',
  String searchLabelText = 'Buscar Account',
  Key? searchFieldKey,
  Key? typeFilterKey,
  Key? listKey,
  TenantAdminAccountProfilePickerCandidateKeyBuilder? candidateKeyBuilder,
}) {
  return showModalBottomSheet<TenantAdminAccountProfile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TenantAdminAccountProfilePicker(
      mode: _TenantAdminAccountProfilePickerMode.single,
      candidatesStreamValue: candidatesStreamValue,
      isLoadingStreamValue: isLoadingStreamValue,
      isPageLoadingStreamValue: isPageLoadingStreamValue,
      hasMoreStreamValue: hasMoreStreamValue,
      errorStreamValue: errorStreamValue,
      loadNextPage: loadNextPage,
      onSearchChanged: onSearchChanged,
      profileTypes: profileTypes,
      title: title,
      emptyMessage: emptyMessage,
      onProfileTypeChanged: onProfileTypeChanged,
      selectedProfileIds: selectedProfileId == null
          ? const <String>{}
          : <String>{selectedProfileId},
      selectedProfileType: selectedProfileType,
      initialSearchQuery: initialSearchQuery,
      searchLabelText: searchLabelText,
      searchFieldKey: searchFieldKey,
      typeFilterKey: typeFilterKey,
      listKey: listKey,
      candidateKeyBuilder: candidateKeyBuilder,
    ),
  );
}

Future<void> showTenantAdminAccountProfileMultiPicker({
  required BuildContext context,
  required StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue,
  required StreamValue<bool> isLoadingStreamValue,
  required StreamValue<bool> isPageLoadingStreamValue,
  required StreamValue<bool> hasMoreStreamValue,
  StreamValue<String?>? errorStreamValue,
  required Future<void> Function() loadNextPage,
  required ValueChanged<String> onSearchChanged,
  required List<TenantAdminProfileTypeDefinition> profileTypes,
  required String title,
  required String emptyMessage,
  required Set<String> selectedProfileIds,
  required void Function(String profileId, bool selected) onSelectionChanged,
  ValueChanged<String?>? onProfileTypeChanged,
  String? selectedProfileType,
  String initialSearchQuery = '',
  String searchLabelText = 'Buscar Account',
  String doneLabel = 'Concluir',
  Key? searchFieldKey,
  Key? typeFilterKey,
  Key? listKey,
  TenantAdminAccountProfilePickerCandidateKeyBuilder? candidateKeyBuilder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TenantAdminAccountProfilePicker(
      mode: _TenantAdminAccountProfilePickerMode.multiple,
      candidatesStreamValue: candidatesStreamValue,
      isLoadingStreamValue: isLoadingStreamValue,
      isPageLoadingStreamValue: isPageLoadingStreamValue,
      hasMoreStreamValue: hasMoreStreamValue,
      errorStreamValue: errorStreamValue,
      loadNextPage: loadNextPage,
      onSearchChanged: onSearchChanged,
      profileTypes: profileTypes,
      title: title,
      emptyMessage: emptyMessage,
      onProfileTypeChanged: onProfileTypeChanged,
      selectedProfileIds: selectedProfileIds,
      selectedProfileType: selectedProfileType,
      initialSearchQuery: initialSearchQuery,
      searchLabelText: searchLabelText,
      doneLabel: doneLabel,
      onMultiSelectionChanged: onSelectionChanged,
      searchFieldKey: searchFieldKey,
      typeFilterKey: typeFilterKey,
      listKey: listKey,
      candidateKeyBuilder: candidateKeyBuilder,
    ),
  );
}

enum _TenantAdminAccountProfilePickerMode { single, multiple }

class _TenantAdminAccountProfilePicker extends StatefulWidget {
  const _TenantAdminAccountProfilePicker({
    required this.mode,
    required this.candidatesStreamValue,
    required this.isLoadingStreamValue,
    required this.isPageLoadingStreamValue,
    required this.hasMoreStreamValue,
    required this.errorStreamValue,
    required this.loadNextPage,
    required this.onSearchChanged,
    required this.profileTypes,
    required this.title,
    required this.emptyMessage,
    required this.selectedProfileIds,
    required this.selectedProfileType,
    required this.initialSearchQuery,
    required this.searchLabelText,
    this.doneLabel = 'Concluir',
    this.onProfileTypeChanged,
    this.onMultiSelectionChanged,
    this.searchFieldKey,
    this.typeFilterKey,
    this.listKey,
    this.candidateKeyBuilder,
  });

  final _TenantAdminAccountProfilePickerMode mode;
  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final StreamValue<bool> isLoadingStreamValue;
  final StreamValue<bool> isPageLoadingStreamValue;
  final StreamValue<bool> hasMoreStreamValue;
  final StreamValue<String?>? errorStreamValue;
  final Future<void> Function() loadNextPage;
  final ValueChanged<String> onSearchChanged;
  final List<TenantAdminProfileTypeDefinition> profileTypes;
  final String title;
  final String emptyMessage;
  final ValueChanged<String?>? onProfileTypeChanged;
  final Set<String> selectedProfileIds;
  final String? selectedProfileType;
  final String initialSearchQuery;
  final String searchLabelText;
  final String doneLabel;
  final void Function(String profileId, bool selected)? onMultiSelectionChanged;
  final Key? searchFieldKey;
  final Key? typeFilterKey;
  final Key? listKey;
  final TenantAdminAccountProfilePickerCandidateKeyBuilder? candidateKeyBuilder;

  @override
  State<_TenantAdminAccountProfilePicker> createState() =>
      _TenantAdminAccountProfilePickerState();
}

class _TenantAdminAccountProfilePickerState
    extends State<_TenantAdminAccountProfilePicker> {
  static const String _allTypes = '__all__';

  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;
  late String _selectedTypeKey;
  late Set<String> _selectedProfileIds;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedTypeKey = _normalizedTypeKey(widget.selectedProfileType);
    _selectedProfileIds = Set<String>.of(widget.selectedProfileIds);
    _scrollController.addListener(_loadNextPageWhenNeeded);
  }

  @override
  void didUpdateWidget(_TenantAdminAccountProfilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedProfileType != widget.selectedProfileType) {
      _selectedTypeKey = _normalizedTypeKey(widget.selectedProfileType);
    }
    if (!_sameIds(oldWidget.selectedProfileIds, widget.selectedProfileIds)) {
      _selectedProfileIds = Set<String>.of(widget.selectedProfileIds);
    }
  }

  bool _sameIds(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final id in left) {
      if (!right.contains(id)) {
        return false;
      }
    }
    return true;
  }

  String _normalizedTypeKey(String? profileType) {
    final normalized = profileType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return _allTypes;
    }
    return normalized;
  }

  void _loadNextPageWhenNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 200 ||
        !widget.hasMoreStreamValue.value ||
        widget.isLoadingStreamValue.value ||
        widget.isPageLoadingStreamValue.value) {
      return;
    }
    widget.loadNextPage();
  }

  Map<String, String> _profileTypeLabels() {
    return {
      for (final profileType in widget.profileTypes)
        if (profileType.type.trim().isNotEmpty)
          profileType.type.trim(): profileType.label,
    };
  }

  List<TenantAdminProfileTypeDefinition> _availableProfileTypes() {
    final uniqueByType = <String, TenantAdminProfileTypeDefinition>{};
    for (final profileType in widget.profileTypes) {
      final typeKey = profileType.type.trim();
      if (typeKey.isEmpty) {
        continue;
      }
      uniqueByType.putIfAbsent(typeKey, () => profileType);
    }
    final profileTypes = uniqueByType.values.toList(growable: false);
    profileTypes.sort((left, right) {
      final labelCompare = left.label.compareTo(right.label);
      if (labelCompare != 0) {
        return labelCompare;
      }
      return left.type.compareTo(right.type);
    });
    return profileTypes;
  }

  void _handleCandidateTap(TenantAdminAccountProfile profile) {
    if (widget.mode == _TenantAdminAccountProfilePickerMode.single) {
      context.router.pop(profile);
      return;
    }

    final nextSelected = !_selectedProfileIds.contains(profile.id);
    setState(() {
      if (nextSelected) {
        _selectedProfileIds.add(profile.id);
      } else {
        _selectedProfileIds.remove(profile.id);
      }
    });
    widget.onMultiSelectionChanged?.call(profile.id, nextSelected);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableProfileTypes = _availableProfileTypes();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        key: const Key('tenantAdminAccountProfilePickerSheet'),
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key:
                  widget.searchFieldKey ??
                  const Key('tenantAdminAccountProfilePickerSearchField'),
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                widget.onSearchChanged(value);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          widget.onSearchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                labelText: widget.searchLabelText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key:
                  widget.typeFilterKey ??
                  const Key('tenantAdminAccountProfilePickerTypeFilter'),
              isExpanded: true,
              initialValue: _selectedTypeKey,
              decoration: const InputDecoration(labelText: 'Tipo de perfil'),
              items: [
                const DropdownMenuItem<String>(
                  value: _allTypes,
                  child: Text('Todos os tipos'),
                ),
                for (final profileType in availableProfileTypes)
                  DropdownMenuItem<String>(
                    value: profileType.type,
                    child: Text(profileType.label),
                  ),
              ],
              onChanged: (value) {
                final next = value ?? _allTypes;
                setState(() {
                  _selectedTypeKey = next;
                });
                widget.onProfileTypeChanged?.call(
                  next == _allTypes ? null : next,
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
            if (widget.mode ==
                _TenantAdminAccountProfilePickerMode.multiple) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScaler = MediaQuery.textScalerOf(context);
                  final shouldStackFooter =
                      constraints.maxWidth <= 360 || textScaler.scale(14) > 16;
                  final selectionSummary = Text(
                    '${_selectedProfileIds.length} selecionado(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                  final doneButton = TextButton(
                    onPressed: () => context.router.maybePop(),
                    child: Text(widget.doneLabel),
                  );

                  if (shouldStackFooter) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selectionSummary,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: doneButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: selectionSummary),
                      const SizedBox(width: 8),
                      doneButton,
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _TenantAdminAccountProfilePickerResults(
      mode: widget.mode,
      candidatesStreamValue: widget.candidatesStreamValue,
      isLoadingStreamValue: widget.isLoadingStreamValue,
      isPageLoadingStreamValue: widget.isPageLoadingStreamValue,
      scrollController: _scrollController,
      emptyMessage: widget.emptyMessage,
      selectedProfileIds: _selectedProfileIds,
      profileTypeLabels: _profileTypeLabels(),
      onCandidateTap: _handleCandidateTap,
      listKey: widget.listKey,
      candidateKeyBuilder: widget.candidateKeyBuilder,
    );
    final errorStreamValue = widget.errorStreamValue;
    if (errorStreamValue == null) {
      return results;
    }
    return StreamValueBuilder<String>(
      streamValue: errorStreamValue,
      onNullWidget: results,
      builder: (context, errorMessage) =>
          _TenantAdminAccountProfilePickerResults(
            mode: widget.mode,
            candidatesStreamValue: widget.candidatesStreamValue,
            isLoadingStreamValue: widget.isLoadingStreamValue,
            isPageLoadingStreamValue: widget.isPageLoadingStreamValue,
            scrollController: _scrollController,
            emptyMessage: widget.emptyMessage,
            selectedProfileIds: _selectedProfileIds,
            errorMessage: errorMessage,
            profileTypeLabels: _profileTypeLabels(),
            onCandidateTap: _handleCandidateTap,
            listKey: widget.listKey,
            candidateKeyBuilder: widget.candidateKeyBuilder,
          ),
    );
  }
}

class _TenantAdminAccountProfilePickerResults extends StatelessWidget {
  const _TenantAdminAccountProfilePickerResults({
    required this.mode,
    required this.candidatesStreamValue,
    required this.isLoadingStreamValue,
    required this.isPageLoadingStreamValue,
    required this.scrollController,
    required this.emptyMessage,
    required this.selectedProfileIds,
    required this.profileTypeLabels,
    required this.onCandidateTap,
    this.errorMessage,
    this.listKey,
    this.candidateKeyBuilder,
  });

  final _TenantAdminAccountProfilePickerMode mode;
  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final StreamValue<bool> isLoadingStreamValue;
  final StreamValue<bool> isPageLoadingStreamValue;
  final ScrollController scrollController;
  final String emptyMessage;
  final Set<String> selectedProfileIds;
  final Map<String, String> profileTypeLabels;
  final void Function(TenantAdminAccountProfile profile) onCandidateTap;
  final String? errorMessage;
  final Key? listKey;
  final TenantAdminAccountProfilePickerCandidateKeyBuilder? candidateKeyBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: isLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<bool>(
          streamValue: isPageLoadingStreamValue,
          builder: (context, isPageLoading) {
            return StreamValueBuilder<List<TenantAdminAccountProfile>>(
              streamValue: candidatesStreamValue,
              onNullWidget: _emptyState(isLoading),
              builder: (context, candidates) =>
                  _candidateState(candidates, isLoading, isPageLoading),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _messageOrEmptyState();
  }

  Widget _candidateState(
    List<TenantAdminAccountProfile> candidates,
    bool isLoading,
    bool isPageLoading,
  ) {
    if (isLoading && candidates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (candidates.isEmpty) {
      return _messageOrEmptyState();
    }

    return ListView.separated(
      key: listKey ?? const Key('tenantAdminAccountProfilePickerList'),
      controller: scrollController,
      itemCount: candidates.length + (isPageLoading ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= candidates.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = candidates[index];
        final selected = selectedProfileIds.contains(profile.id);
        final candidateKey =
            candidateKeyBuilder?.call(profile) ??
            Key('tenantAdminAccountProfilePickerCandidate_${profile.id}');
        final subtitle = Text(
          profileTypeLabels[profile.profileType] ?? profile.profileType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
        final title = Text(
          profile.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

        if (mode == _TenantAdminAccountProfilePickerMode.multiple) {
          return CheckboxListTile(
            key: candidateKey,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: selected,
            title: title,
            subtitle: subtitle,
            onChanged: (_) => onCandidateTap(profile),
          );
        }

        return Card(
          child: ListTile(
            key: candidateKey,
            leading: const Icon(Icons.person_outline),
            title: title,
            subtitle: subtitle,
            trailing: Icon(selected ? Icons.check_circle : Icons.chevron_right),
            onTap: () => onCandidateTap(profile),
          ),
        );
      },
    );
  }

  Widget _messageOrEmptyState() {
    final message = errorMessage;
    if (message != null && message.trim().isNotEmpty) {
      return Center(child: Text(message, textAlign: TextAlign.center));
    }
    return Center(child: Text(emptyMessage));
  }
}
