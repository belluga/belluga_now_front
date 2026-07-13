import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

/// Canonical, tenant-admin selector for choosing one Account Profile from an
/// already-authorized candidate collection. Candidate discovery and filtering
/// remain controller responsibilities; this widget owns only picker-local UI.
Future<TenantAdminAccountProfile?> showTenantAdminAccountProfilePicker({
  required BuildContext context,
  required StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue,
  required StreamValue<bool> isLoadingStreamValue,
  required StreamValue<bool> isPageLoadingStreamValue,
  required StreamValue<bool> hasMoreStreamValue,
  required StreamValue<String?> errorStreamValue,
  required Future<void> Function() loadNextPage,
  required String title,
  required String emptyMessage,
  String? selectedProfileId,
}) {
  return showModalBottomSheet<TenantAdminAccountProfile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TenantAdminAccountProfilePicker(
      candidatesStreamValue: candidatesStreamValue,
      isLoadingStreamValue: isLoadingStreamValue,
      isPageLoadingStreamValue: isPageLoadingStreamValue,
      hasMoreStreamValue: hasMoreStreamValue,
      errorStreamValue: errorStreamValue,
      loadNextPage: loadNextPage,
      title: title,
      emptyMessage: emptyMessage,
      selectedProfileId: selectedProfileId,
    ),
  );
}

class _TenantAdminAccountProfilePicker extends StatefulWidget {
  const _TenantAdminAccountProfilePicker({
    required this.candidatesStreamValue,
    required this.isLoadingStreamValue,
    required this.isPageLoadingStreamValue,
    required this.hasMoreStreamValue,
    required this.errorStreamValue,
    required this.loadNextPage,
    required this.title,
    required this.emptyMessage,
    required this.selectedProfileId,
  });

  final StreamValue<List<TenantAdminAccountProfile>> candidatesStreamValue;
  final StreamValue<bool> isLoadingStreamValue;
  final StreamValue<bool> isPageLoadingStreamValue;
  final StreamValue<bool> hasMoreStreamValue;
  final StreamValue<String?> errorStreamValue;
  final Future<void> Function() loadNextPage;
  final String title;
  final String emptyMessage;
  final String? selectedProfileId;

  @override
  State<_TenantAdminAccountProfilePicker> createState() =>
      _TenantAdminAccountProfilePickerState();
}

class _TenantAdminAccountProfilePickerState
    extends State<_TenantAdminAccountProfilePicker> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageWhenNeeded);
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

  @override
  void dispose() {
    _scrollController.dispose();
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
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: StreamValueBuilder<String?>(
                streamValue: widget.errorStreamValue,
                builder: (context, error) {
                  return StreamValueBuilder<bool>(
                    streamValue: widget.isLoadingStreamValue,
                    builder: (context, isLoading) {
                      return StreamValueBuilder<bool>(
                        streamValue: widget.isPageLoadingStreamValue,
                        builder: (context, isPageLoading) {
                          return StreamValueBuilder<
                            List<TenantAdminAccountProfile>
                          >(
                            streamValue: widget.candidatesStreamValue,
                            builder: (context, candidates) {
                              if (isLoading && candidates.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (error != null &&
                                  error.trim().isNotEmpty &&
                                  candidates.isEmpty) {
                                return Center(
                                  child: Text(
                                    error,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              if (candidates.isEmpty) {
                                return Center(child: Text(widget.emptyMessage));
                              }

                              return ListView.separated(
                                key: const Key(
                                  'tenantAdminAccountProfilePickerList',
                                ),
                                controller: _scrollController,
                                itemCount:
                                    candidates.length + (isPageLoading ? 1 : 0),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index >= candidates.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final profile = candidates[index];
                                  final selected =
                                      profile.id == widget.selectedProfileId;
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: Text(profile.displayName),
                                      subtitle: Text(
                                        profile.slug ?? profile.profileType,
                                      ),
                                      trailing: Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.chevron_right,
                                      ),
                                      onTap: () => context.router.pop(profile),
                                    ),
                                  );
                                },
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
    );
  }
}
