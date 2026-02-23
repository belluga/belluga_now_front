import 'package:flutter/material.dart';

class TenantAdminListControlsPanel extends StatelessWidget {
  const TenantAdminListControlsPanel({
    super.key,
    required this.filterLabel,
    required this.filterField,
    required this.showSearchField,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.searchHintText,
    required this.manageButtonLabel,
    required this.onManagePressed,
    this.searchToggleKey,
    this.searchFieldKey,
    this.manageButtonKey,
  });

  final String filterLabel;
  final Widget filterField;
  final bool showSearchField;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final String searchHintText;
  final String manageButtonLabel;
  final VoidCallback onManagePressed;
  final Key? searchToggleKey;
  final Key? searchFieldKey;
  final Key? manageButtonKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searchActive = showSearchField;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  filterLabel,
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton.filledTonal(
                key: searchToggleKey,
                tooltip: searchActive ? 'Ocultar busca' : 'Buscar',
                onPressed: onToggleSearch,
                icon: Icon(searchActive ? Icons.close : Icons.search),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: manageButtonKey,
                onPressed: onManagePressed,
                icon: const Icon(Icons.tune_rounded),
                label: Text(manageButtonLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          if (showSearchField) ...[
            const SizedBox(height: 10),
            TextField(
              key: searchFieldKey,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: searchHintText,
                labelText: 'Pesquisa',
              ),
            ),
          ],
          const SizedBox(height: 10),
          filterField,
        ],
      ),
    );
  }
}
