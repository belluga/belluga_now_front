import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
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
                  _buildVisualHeader(context),
                  const SizedBox(height: 16),
                  _buildRow(context, 'Slug', asset.slug),
                  const SizedBox(height: 8),
                  _buildRow(context, 'Tipo', asset.profileType),
                  const SizedBox(height: 8),
                  _buildRow(
                      context, 'Status', asset.isActive ? 'Ativo' : 'Inativo'),
                  if (asset.bio != null && asset.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRow(context, 'Bio', _stripHtml(asset.bio!.trim())),
                  ],
                  if (asset.content != null &&
                      asset.content!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRow(
                      context,
                      'Conteudo',
                      _stripHtml(asset.content!.trim()),
                    ),
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

  Widget _buildVisualHeader(BuildContext context) {
    final coverUrl = asset.coverUrl;
    final avatarUrl = asset.avatarUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coverUrl != null && coverUrl.isNotEmpty)
          BellugaNetworkImage(
            coverUrl,
            height: 160,
            fit: BoxFit.cover,
            clipBorderRadius: BorderRadius.circular(12),
            errorWidget: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          )
        else
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              BellugaNetworkImage(
                avatarUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                clipBorderRadius: BorderRadius.circular(36),
                errorWidget: _avatarFallback(context),
              )
            else
              _avatarFallback(context),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                asset.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(36),
      ),
      child: const Icon(Icons.photo_outlined),
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

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
