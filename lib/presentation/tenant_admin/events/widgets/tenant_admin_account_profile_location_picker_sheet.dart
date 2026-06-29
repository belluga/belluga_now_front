import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminEventModalCloser =
    Future<bool> Function<T>(BuildContext context, [T? result]);

Future<String?> showTenantAdminAccountProfileLocationPickerSheet({
  required BuildContext context,
  required TenantAdminEventsController controller,
  required String? selectedLocationProfileId,
  required String title,
  required String subtitle,
  required String keyPrefix,
  required TenantAdminEventModalCloser closeModalSheet,
  bool includeEmptyOption = true,
  String emptyOptionLabel = 'Sem local específico',
  String? selectedLocationFallbackLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return _TenantAdminAccountProfileLocationPickerSheet(
        controller: controller,
        selectedLocationProfileId: selectedLocationProfileId,
        selectedLocationFallbackLabel: selectedLocationFallbackLabel,
        title: title,
        subtitle: subtitle,
        keyPrefix: keyPrefix,
        includeEmptyOption: includeEmptyOption,
        emptyOptionLabel: emptyOptionLabel,
        closeModalSheet: closeModalSheet,
      );
    },
  );
}

class _TenantAdminAccountProfileLocationPickerSheet extends StatelessWidget {
  const _TenantAdminAccountProfileLocationPickerSheet({
    required this.controller,
    required this.selectedLocationProfileId,
    required this.selectedLocationFallbackLabel,
    required this.title,
    required this.subtitle,
    required this.keyPrefix,
    required this.includeEmptyOption,
    required this.emptyOptionLabel,
    required this.closeModalSheet,
  });

  final TenantAdminEventsController controller;
  final String? selectedLocationProfileId;
  final String? selectedLocationFallbackLabel;
  final String title;
  final String subtitle;
  final String keyPrefix;
  final bool includeEmptyOption;
  final String emptyOptionLabel;
  final TenantAdminEventModalCloser closeModalSheet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(title: Text(title), subtitle: Text(subtitle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: Key('${keyPrefix}SearchField'),
                  controller: controller.accountProfilePickerSearchController,
                  autofocus: true,
                  onChanged: controller.updateAccountProfilePickerSearchQuery,
                  decoration: const InputDecoration(
                    labelText: 'Buscar local',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamValueBuilder<String>(
                  streamValue: controller.accountProfilePickerErrorStreamValue,
                  builder: (context, searchError) {
                    return StreamValueBuilder<bool>(
                      streamValue:
                          controller.accountProfilePickerLoadingStreamValue,
                      builder: (context, isSearchLoading) {
                        return StreamValueBuilder<bool>(
                          streamValue: controller
                              .accountProfilePickerPageLoadingStreamValue,
                          builder: (context, isSearchPageLoading) {
                            return StreamValueBuilder<
                              List<TenantAdminAccountProfile>
                            >(
                              streamValue: controller
                                  .accountProfilePickerResultsStreamValue,
                              builder: (context, searchResults) {
                                if (isSearchLoading && searchResults.isEmpty) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (searchError.isNotEmpty &&
                                    searchResults.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          searchError,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton(
                                          onPressed: controller
                                              .retryAccountProfilePickerSearch,
                                          child: const Text('Tentar novamente'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final options = _buildOptions(searchResults);
                                if (options.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Nenhum local elegível encontrado.',
                                    ),
                                  );
                                }

                                final itemCount =
                                    options.length +
                                    (isSearchPageLoading ? 1 : 0);

                                return Scrollbar(
                                  child: ListView.builder(
                                    key: Key('${keyPrefix}OptionsList'),
                                    controller: controller
                                        .accountProfilePickerScrollController,
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: itemCount,
                                    itemBuilder: (context, index) {
                                      if (index >= options.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final option = options[index];
                                      final isSelected =
                                          selectedLocationProfileId ==
                                              option.value ||
                                          (selectedLocationProfileId == null &&
                                              option.value.isEmpty);

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: TextButton.icon(
                                            key: Key(
                                              '${keyPrefix}Option_${option.value.isEmpty ? 'none' : option.value}',
                                            ),
                                            style: TextButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                            ),
                                            onPressed: () => unawaited(
                                              closeModalSheet(
                                                context,
                                                option.value,
                                              ),
                                            ),
                                            icon: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                  )
                                                : const SizedBox(width: 18),
                                            label: Text(option.label),
                                          ),
                                        ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String value, String label})> _buildOptions(
    List<TenantAdminAccountProfile> results,
  ) {
    final options = <({String value, String label})>[
      if (includeEmptyOption) (value: '', label: emptyOptionLabel),
    ];
    final normalizedQuery = controller
        .accountProfilePickerQueryStreamValue
        .value
        .trim();
    final selectedId = selectedLocationProfileId?.trim();
    final hasSelectedResult =
        selectedId != null &&
        selectedId.isNotEmpty &&
        results.any((profile) => profile.id == selectedId);
    if (normalizedQuery.isEmpty &&
        selectedId != null &&
        selectedId.isNotEmpty &&
        !hasSelectedResult) {
      final selectedCandidate = controller.knownVenueCandidate(selectedId);
      final fallbackLabel =
          selectedCandidate?.displayName ??
          selectedLocationFallbackLabel?.trim() ??
          selectedId;
      options.add((value: selectedId, label: fallbackLabel));
    }

    options.addAll(
      results.map((profile) => (value: profile.id, label: profile.displayName)),
    );

    return options;
  }
}
