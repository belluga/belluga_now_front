import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_occurrence_related_profile_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/widgets/tenant_admin_account_profile_location_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

final class TenantAdminOccurrenceRelatedProfilePickerSheet
    extends StatelessWidget {
  const TenantAdminOccurrenceRelatedProfilePickerSheet({
    super.key,
    required this.controller,
    required this.closeModalSheet,
  });

  final TenantAdminOccurrenceRelatedProfilePickerController controller;
  final TenantAdminEventModalCloser closeModalSheet;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 200) {
      unawaited(controller.loadNextPage());
    }
    return false;
  }

  TenantAdminAccountProfile _profile(
    TenantAdminAccountProfileSelectionSummary item,
  ) {
    final displayName = item.displayName?.trim();
    return tenantAdminAccountProfileFromRaw(
      id: item.id,
      accountId: item.id,
      profileType: 'account_profile',
      displayName: displayName == null || displayName.isEmpty
          ? item.id
          : displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: StreamValueBuilder(
          streamValue: controller.selectedGroupStreamValue,
          builder: (context, _) {
            final selectedGroup = controller.selectedGroupStreamValue.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ListTile(
                  title: Text('Perfis próprios da data'),
                  subtitle: Text(
                    'Selecione um participante já vinculado a esta ocorrência.',
                  ),
                ),
                if (controller.groups.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: DropdownButtonFormField<String>(
                      key: const Key('tenantAdminProgrammingCandidateGroup'),
                      initialValue: selectedGroup?.id,
                      decoration: const InputDecoration(labelText: 'Grupo'),
                      items: [
                        for (final group in controller.groups)
                          DropdownMenuItem<String>(
                            value: group.id,
                            child: Text(group.label),
                          ),
                      ],
                      onChanged: (groupId) {
                        if (groupId != null) {
                          unawaited(controller.selectGroup(groupId));
                        }
                      },
                    ),
                  ),
                StreamValueBuilder(
                  streamValue: controller.searchAvailableStreamValue,
                  builder: (context, _) {
                    if (!controller.searchAvailableStreamValue.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        key: ValueKey(
                          'tenantAdminProgrammingCandidateSearch_${selectedGroup?.id}',
                        ),
                        onChanged: controller.updateSearch,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          labelText: 'Buscar neste grupo',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(child: _results(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    return StreamValueBuilder(
      streamValue: controller.isLoadingStreamValue,
      builder: (context, _) {
        if (controller.isLoadingStreamValue.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamValueBuilder(
          streamValue: controller.itemsStreamValue,
          builder: (context, _) {
            final error = controller.errorStreamValue.value;
            if (error != null && error.trim().isNotEmpty) {
              return Center(child: Text(error));
            }
            final items = controller.itemsStreamValue.value;
            if (items.isEmpty) {
              return const Center(
                child: Text('Nenhum perfil próprio disponível.'),
              );
            }
            return StreamValueBuilder(
              streamValue: controller.isPageLoadingStreamValue,
              builder: (context, _) {
                final pageLoading = controller.isPageLoadingStreamValue.value;
                return NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: ListView.builder(
                    itemCount: items.length + (pageLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = items[index];
                      return ListTile(
                        key: Key(
                          'tenantAdminOccurrenceProgrammingCandidate_${item.id}',
                        ),
                        leading: const Icon(Icons.person_outline),
                        title: Text(item.displayName ?? item.id),
                        subtitle: Text(item.id),
                        onTap: () =>
                            unawaited(closeModalSheet(context, _profile(item))),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
