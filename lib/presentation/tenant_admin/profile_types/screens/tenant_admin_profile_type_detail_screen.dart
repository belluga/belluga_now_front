import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:flutter/material.dart';

class TenantAdminProfileTypeDetailScreen extends StatelessWidget {
  const TenantAdminProfileTypeDetailScreen({
    super.key,
    required this.definition,
  });

  final TenantAdminProfileTypeDefinition definition;

  @override
  Widget build(BuildContext context) {
    final capabilities = <String>[
      if (definition.capabilities.isFavoritable) 'Favoritavel',
      if (definition.capabilities.isPoiEnabled) 'POI habilitado',
      if (definition.capabilities.hasBio) 'Bio',
      if (definition.capabilities.hasTaxonomies) 'Taxonomias',
      if (definition.capabilities.hasAvatar) 'Avatar',
      if (definition.capabilities.hasCover) 'Capa',
      if (definition.capabilities.hasEvents) 'Agenda',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(definition.label),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {
              context.router.push(
                TenantAdminProfileTypeEditRoute(
                  profileType: definition.type,
                  definition: definition,
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes do tipo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildRow(context, 'Slug', definition.type),
                  const SizedBox(height: 8),
                  _buildRow(context, 'Label', definition.label),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capacidades',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: capabilities
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          if (definition.allowedTaxonomies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxonomias permitidas',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: definition.allowedTaxonomies
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
