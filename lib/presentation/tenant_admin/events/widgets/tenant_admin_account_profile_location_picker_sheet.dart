import 'dart:async';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:flutter/material.dart';

typedef TenantAdminEventModalCloser = Future<bool> Function<T>(
  BuildContext context, [
  T? result,
]);

Future<String?> showTenantAdminAccountProfileLocationPickerSheet({
  required BuildContext context,
  required List<TenantAdminAccountProfile> venues,
  required String? selectedLocationProfileId,
  required String title,
  required String subtitle,
  required String keyPrefix,
  required TenantAdminEventModalCloser closeModalSheet,
  bool includeEmptyOption = true,
  String emptyOptionLabel = 'Sem local específico',
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return _TenantAdminAccountProfileLocationPickerSheet(
        venues: venues,
        selectedLocationProfileId: selectedLocationProfileId,
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

class _TenantAdminAccountProfileLocationPickerSheet extends StatefulWidget {
  const _TenantAdminAccountProfileLocationPickerSheet({
    required this.venues,
    required this.selectedLocationProfileId,
    required this.title,
    required this.subtitle,
    required this.keyPrefix,
    required this.includeEmptyOption,
    required this.emptyOptionLabel,
    required this.closeModalSheet,
  });

  final List<TenantAdminAccountProfile> venues;
  final String? selectedLocationProfileId;
  final String title;
  final String subtitle;
  final String keyPrefix;
  final bool includeEmptyOption;
  final String emptyOptionLabel;
  final TenantAdminEventModalCloser closeModalSheet;

  @override
  State<_TenantAdminAccountProfileLocationPickerSheet> createState() =>
      _TenantAdminAccountProfileLocationPickerSheetState();
}

class _TenantAdminAccountProfileLocationPickerSheetState
    extends State<_TenantAdminAccountProfileLocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<({String value, String label})> get _options {
    final normalizedQuery = _query.trim().toLowerCase();
    final venueOptions = widget.venues
        .where(
          (venue) =>
              normalizedQuery.isEmpty ||
              venue.displayName.toLowerCase().contains(normalizedQuery),
        )
        .map((venue) => (value: venue.id, label: venue.displayName))
        .toList(growable: false);

    return [
      if (widget.includeEmptyOption)
        (value: '', label: widget.emptyOptionLabel),
      ...venueOptions,
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

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
              ListTile(
                title: Text(widget.title),
                subtitle: Text(widget.subtitle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: Key('${widget.keyPrefix}SearchField'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'Buscar local',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    key: Key('${widget.keyPrefix}OptionsList'),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected =
                          widget.selectedLocationProfileId == option.value ||
                              (widget.selectedLocationProfileId == null &&
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
                              '${widget.keyPrefix}Option_${option.value.isEmpty ? 'none' : option.value}',
                            ),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onPressed: () => unawaited(
                              widget.closeModalSheet(context, option.value),
                            ),
                            icon: isSelected
                                ? const Icon(Icons.check, size: 18)
                                : const SizedBox(width: 18),
                            label: Text(option.label),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
