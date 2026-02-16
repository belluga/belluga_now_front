import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:flutter/material.dart';

class TenantAdminStaticAssetDetailScreen extends StatelessWidget {
  const TenantAdminStaticAssetDetailScreen({
    super.key,
    required this.asset,
  });

  final TenantAdminStaticAsset asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.displayName),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {
              context.router.push(
                TenantAdminStaticAssetEditRoute(assetId: asset.id),
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
                    'Detalhes do ativo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildRow(context, 'Slug', asset.slug),
                  const SizedBox(height: 8),
                  _buildRow(context, 'Tipo', asset.profileType),
                  const SizedBox(height: 8),
                  _buildRow(
                      context, 'Status', asset.isActive ? 'Ativo' : 'Inativo'),
                  if (asset.bio != null && asset.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRow(context, 'Bio', asset.bio!.trim()),
                  ],
                  if (asset.content != null &&
                      asset.content!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRow(context, 'Conteudo', asset.content!.trim()),
                  ],
                  if (asset.location != null) ...[
                    const SizedBox(height: 8),
                    _buildRow(
                      context,
                      'Localizacao',
                      '${asset.location!.latitude.toStringAsFixed(6)}, ${asset.location!.longitude.toStringAsFixed(6)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (asset.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChipsSection(context, 'Tags', asset.tags),
          ],
          if (asset.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChipsSection(context, 'Categorias', asset.categories),
          ],
          if (asset.taxonomyTerms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChipsSection(
              context,
              'Taxonomias',
              asset.taxonomyTerms
                  .map((term) => '${term.type}:${term.value}')
                  .toList(growable: false),
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

  Widget _buildChipsSection(
    BuildContext context,
    String title,
    List<String> values,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  values.map((value) => Chip(label: Text(value))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
