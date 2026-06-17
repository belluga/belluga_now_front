import 'dart:async';

import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountProfileGalleryEditor extends StatelessWidget {
  const TenantAdminAccountProfileGalleryEditor({
    super.key,
    required this.groups,
    required this.totalItemCount,
    required this.maxGroups,
    required this.maxItems,
    required this.onAddGroup,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onAddItemRequested,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onDescriptionChanged,
  });

  final List<TenantAdminAccountProfileGalleryGroupDraft> groups;
  final int totalItemCount;
  final int maxGroups;
  final int maxItems;
  final VoidCallback onAddGroup;
  final void Function(String groupId, String subtitle) onRenameGroup;
  final void Function(String groupId, int delta) onMoveGroup;
  final void Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddItemRequested;
  final Future<void> Function(String groupId, String itemId) onReplaceItemRequested;
  final void Function(String groupId, String itemId, int delta) onMoveItem;
  final void Function(String groupId, String itemId) onRemoveItem;
  final void Function(String groupId, String itemId, String description)
      onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final itemLabel = '$totalItemCount / $maxItems fotos';

    return TenantAdminFormSectionCard(
      title: 'Galerias de fotos',
      description:
          'Organize grupos públicos com subtítulo e descrição opcional por foto.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < groups.length; index++) ...[
            _GalleryGroupCard(
              group: groups[index],
              index: index,
              totalGroups: groups.length,
              totalItemCount: totalItemCount,
              maxItems: maxItems,
              onRenameGroup: onRenameGroup,
              onMoveGroup: onMoveGroup,
              onRemoveGroup: onRemoveGroup,
              onAddItemRequested: onAddItemRequested,
              onReplaceItemRequested: onReplaceItemRequested,
              onMoveItem: onMoveItem,
              onRemoveItem: onRemoveItem,
              onDescriptionChanged: onDescriptionChanged,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            key: const Key('tenantAdminEditAddGalleryGroupButton'),
            onPressed: groups.length >= maxGroups ? null : onAddGroup,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar grupo de fotos'),
          ),
        ],
      ),
    );
  }
}

class _GalleryGroupCard extends StatelessWidget {
  const _GalleryGroupCard({
    required this.group,
    required this.index,
    required this.totalGroups,
    required this.totalItemCount,
    required this.maxItems,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onAddItemRequested,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onDescriptionChanged,
  });

  final TenantAdminAccountProfileGalleryGroupDraft group;
  final int index;
  final int totalGroups;
  final int totalItemCount;
  final int maxItems;
  final void Function(String groupId, String subtitle) onRenameGroup;
  final void Function(String groupId, int delta) onMoveGroup;
  final void Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddItemRequested;
  final Future<void> Function(String groupId, String itemId) onReplaceItemRequested;
  final void Function(String groupId, String itemId, int delta) onMoveItem;
  final void Function(String groupId, String itemId) onRemoveItem;
  final void Function(String groupId, String itemId, String description)
      onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: Key('tenantAdminGalleryGroup_${group.groupId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('tenantAdminGalleryGroupSubtitle_${group.groupId}'),
                  initialValue: group.subtitle,
                  decoration: const InputDecoration(
                    labelText: 'Subtítulo do agrupamento',
                  ),
                  onChanged: (value) => onRenameGroup(group.groupId, value),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subtítulo obrigatório.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Mover para cima',
                    onPressed:
                        index == 0 ? null : () => onMoveGroup(group.groupId, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Mover para baixo',
                    onPressed: index >= totalGroups - 1
                        ? null
                        : () => onMoveGroup(group.groupId, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Remover grupo',
                    onPressed: () => onRemoveGroup(group.groupId),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (group.items.isEmpty)
            Text(
              'Adicione ao menos uma foto neste grupo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            Column(
              children: [
                for (var itemIndex = 0; itemIndex < group.items.length; itemIndex++) ...[
                  _GalleryItemCard(
                    groupId: group.groupId,
                    item: group.items[itemIndex],
                    index: itemIndex,
                    totalItems: group.items.length,
                    onReplaceItemRequested: onReplaceItemRequested,
                    onMoveItem: onMoveItem,
                    onRemoveItem: onRemoveItem,
                    onDescriptionChanged: onDescriptionChanged,
                  ),
                  if (itemIndex < group.items.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: Key('tenantAdminGalleryGroupAddItem_${group.groupId}'),
            onPressed: totalItemCount >= maxItems
                ? null
                : () => unawaited(onAddItemRequested(group.groupId)),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Adicionar foto'),
          ),
        ],
      ),
    );
  }
}

class _GalleryItemCard extends StatelessWidget {
  const _GalleryItemCard({
    required this.groupId,
    required this.item,
    required this.index,
    required this.totalItems,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onDescriptionChanged,
  });

  final String groupId;
  final TenantAdminAccountProfileGalleryItemDraft item;
  final int index;
  final int totalItems;
  final Future<void> Function(String groupId, String itemId) onReplaceItemRequested;
  final void Function(String groupId, String itemId, int delta) onMoveItem;
  final void Function(String groupId, String itemId) onRemoveItem;
  final void Function(String groupId, String itemId, String description)
      onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('tenantAdminGalleryItem_${item.itemId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GalleryItemPreview(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: Key('tenantAdminGalleryItemDescription_${item.itemId}'),
                  initialValue: item.description ?? '',
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição da foto',
                    hintText: 'Opcional',
                  ),
                  onChanged: (value) =>
                      onDescriptionChanged(groupId, item.itemId, value),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: Key('tenantAdminGalleryItemReplace_${item.itemId}'),
                      onPressed: () => unawaited(
                        onReplaceItemRequested(groupId, item.itemId),
                      ),
                      icon: const Icon(Icons.image_search_outlined),
                      label: const Text('Trocar foto'),
                    ),
                    if (totalItems > 1)
                      IconButton(
                        tooltip: 'Mover para cima',
                        onPressed: index == 0
                            ? null
                            : () => onMoveItem(groupId, item.itemId, -1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    if (totalItems > 1)
                      IconButton(
                        tooltip: 'Mover para baixo',
                        onPressed: index >= totalItems - 1
                            ? null
                            : () => onMoveItem(groupId, item.itemId, 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    IconButton(
                      tooltip: 'Remover foto',
                      onPressed: () => onRemoveItem(groupId, item.itemId),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryItemPreview extends StatelessWidget {
  const _GalleryItemPreview({required this.item});

  final TenantAdminAccountProfileGalleryItemDraft item;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(10));

    if (item.uploadFile != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: TenantAdminXFilePreview(
          file: item.uploadFile!,
          width: 112,
          height: 84,
          fit: BoxFit.cover,
        ),
      );
    }

    final previewUrl = item.previewUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return BellugaNetworkImage(
        previewUrl,
        width: 112,
        height: 84,
        fit: BoxFit.cover,
        clipBorderRadius: borderRadius,
      );
    }

    return Container(
      width: 112,
      height: 84,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.image_outlined),
    );
  }
}
