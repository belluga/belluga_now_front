import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

Future<List<TenantAdminAccountProfileSelectionSummary>?>
showTenantAdminAccountProfileCandidatePicker({
  required BuildContext context,
  required TenantAdminAccountProfileCandidatePickerController controller,
  required String title,
  required String emptyMessage,
  required bool closeOnSelection,
  String searchLabelText = 'Buscar perfil',
  String doneLabel = 'Concluir',
}) {
  return showModalBottomSheet<List<TenantAdminAccountProfileSelectionSummary>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TenantAdminAccountProfileCandidatePicker(
      controller: controller,
      title: title,
      emptyMessage: emptyMessage,
      closeOnSelection: closeOnSelection,
      searchLabelText: searchLabelText,
      doneLabel: doneLabel,
    ),
  );
}

class _TenantAdminAccountProfileCandidatePicker extends StatefulWidget {
  const _TenantAdminAccountProfileCandidatePicker({
    required this.controller,
    required this.title,
    required this.emptyMessage,
    required this.closeOnSelection,
    required this.searchLabelText,
    required this.doneLabel,
  });

  final TenantAdminAccountProfileCandidatePickerController controller;
  final String title;
  final String emptyMessage;
  final bool closeOnSelection;
  final String searchLabelText;
  final String doneLabel;

  @override
  State<_TenantAdminAccountProfileCandidatePicker> createState() =>
      _TenantAdminAccountProfileCandidatePickerState();
}

class _TenantAdminAccountProfileCandidatePickerState
    extends State<_TenantAdminAccountProfileCandidatePicker> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageWhenNeeded);
    unawaited(widget.controller.initialize());
  }

  void _loadNextPageWhenNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 200 ||
        !widget.controller.hasMoreStreamValue.value ||
        widget.controller.isLoadingStreamValue.value ||
        widget.controller.isPageLoadingStreamValue.value) {
      return;
    }
    widget.controller.loadNextPage();
  }

  void _select(TenantAdminAccountProfileCandidate candidate) {
    if (!widget.controller.toggleSelection(candidate)) return;
    if (widget.closeOnSelection) {
      context.router.pop(widget.controller.selectedSummaries);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
      child: SizedBox(
        key: const Key('tenantAdminAccountProfileCandidatePickerSheet'),
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const Key(
                'tenantAdminAccountProfileCandidatePickerSearchField',
              ),
              controller: _searchController,
              onChanged: widget.controller.updateSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    StreamValueBuilder<
                      List<TenantAdminAccountProfileCandidate>
                    >(
                      streamValue: widget.controller.candidatesStreamValue,
                      builder: (context, _) => _searchController.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchController.clear();
                                widget.controller.updateSearch('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                labelText: widget.searchLabelText,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
            StreamValueBuilder<bool>(
              streamValue: widget.controller.browseLimitReachedStreamValue,
              builder: (context, browseLimitReached) => browseLimitReached
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Há mais perfis disponíveis. Refine a busca para encontrar outros resultados.',
                        key: Key(
                          'tenantAdminAccountProfileCandidateBrowseLimitHint',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (!widget.closeOnSelection) ...[
              const SizedBox(height: 12),
              StreamValueBuilder<
                List<TenantAdminAccountProfileSelectionSummary>
              >(
                streamValue: widget.controller.selectedSummariesStreamValue,
                builder: (context, selections) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.controller.maxSelections == null
                            ? '${selections.length} selecionado(s)'
                            : '${selections.length} / ${widget.controller.maxSelections} selecionado(s) por operação',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.router.pop(selections),
                      child: Text(widget.doneLabel),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return StreamValueBuilder<bool>(
      streamValue: widget.controller.isLoadingStreamValue,
      builder: (context, isLoading) => StreamValueBuilder<bool>(
        streamValue: widget.controller.isPageLoadingStreamValue,
        builder: (context, isPageLoading) => StreamValueBuilder<String>(
          streamValue: widget.controller.errorStreamValue,
          onNullWidget: _buildCandidates(isLoading, isPageLoading, null),
          builder: (context, error) =>
              _buildCandidates(isLoading, isPageLoading, error),
        ),
      ),
    );
  }

  Widget _buildCandidates(bool isLoading, bool isPageLoading, String? error) {
    return StreamValueBuilder<List<TenantAdminAccountProfileCandidate>>(
      streamValue: widget.controller.candidatesStreamValue,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, candidates) {
        if (isLoading && candidates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (candidates.isEmpty) {
          return Center(
            child: Text(
              error?.trim().isNotEmpty == true ? error! : widget.emptyMessage,
              textAlign: TextAlign.center,
            ),
          );
        }
        return StreamValueBuilder<
          List<TenantAdminAccountProfileSelectionSummary>
        >(
          streamValue: widget.controller.selectedSummariesStreamValue,
          builder: (context, selections) {
            final selectedIds = selections.map((entry) => entry.id).toSet();
            return ListView.separated(
              key: const Key('tenantAdminAccountProfileCandidatePickerList'),
              controller: _scrollController,
              itemCount: candidates.length + (isPageLoading ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= candidates.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final candidate = candidates[index];
                final selected = selectedIds.contains(candidate.id);
                if (widget.closeOnSelection) {
                  return Card(
                    child: ListTile(
                      key: Key(
                        'tenantAdminAccountProfileCandidate_${candidate.id}',
                      ),
                      leading: const Icon(Icons.person_outline),
                      title: Text(candidate.displayName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _select(candidate),
                    ),
                  );
                }
                return CheckboxListTile(
                  key: Key(
                    'tenantAdminAccountProfileCandidate_${candidate.id}',
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: selected,
                  title: Text(candidate.displayName),
                  onChanged: (_) => _select(candidate),
                );
              },
            );
          },
        );
      },
    );
  }
}
