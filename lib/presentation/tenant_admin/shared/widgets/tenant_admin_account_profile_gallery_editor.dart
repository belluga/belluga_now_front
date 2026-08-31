import 'dart:async';

import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountProfileGalleryEditor extends StatelessWidget {
  const TenantAdminAccountProfileGalleryEditor({
    super.key,
    required this.groups,
    required this.maxGroups,
    required this.maxItemsPerGallery,
    required this.busy,
    required this.fieldErrors,
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
  final int maxGroups;
  final int maxItemsPerGallery;
  final bool busy;
  final Map<String, String> fieldErrors;
  final Future<void> Function() onAddGroup;
  final Future<void> Function(String groupId, String subtitle) onRenameGroup;
  final Future<void> Function(String groupId, int delta) onMoveGroup;
  final Future<void> Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddItemRequested;
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String description)
  onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final galleryState = _capacityState(groups.length, maxGroups);

    return TenantAdminFormSectionCard(
      title: 'Galerias',
      description:
          'Organize fotos e vídeos do YouTube. Grupos vazios ficam disponíveis '
          'para edição e não aparecem no perfil público.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${groups.length} / $maxGroups galerias · ${_stateLabel(galleryState)}',
          ),
          if (galleryState == TenantAdminGalleryCapacityState.overLimit)
            Text(
              'Remova pelo menos ${groups.length - maxGroups} '
              '${groups.length - maxGroups == 1 ? 'galeria' : 'galerias'} '
              'para voltar ao limite do plano.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (fieldErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              fieldErrors.values.join('\n'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          for (var index = 0; index < groups.length; index++) ...[
            _GalleryGroupCard(
              group: groups[index],
              index: index,
              totalGroups: groups.length,
              maxItems: maxItemsPerGallery,
              busy: busy,
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
            onPressed:
                busy ||
                    galleryState != TenantAdminGalleryCapacityState.available
                ? null
                : () => unawaited(onAddGroup()),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar galeria'),
          ),
        ],
      ),
    );
  }

  TenantAdminGalleryCapacityState _capacityState(int count, int maximum) {
    if (count > maximum) return TenantAdminGalleryCapacityState.overLimit;
    if (count == maximum) return TenantAdminGalleryCapacityState.atLimit;
    return TenantAdminGalleryCapacityState.available;
  }

  String _stateLabel(TenantAdminGalleryCapacityState state) => switch (state) {
    TenantAdminGalleryCapacityState.available => 'disponível',
    TenantAdminGalleryCapacityState.atLimit => 'no limite do plano',
    TenantAdminGalleryCapacityState.overLimit => 'acima do limite do plano',
  };
}

class _GalleryGroupCard extends StatelessWidget {
  const _GalleryGroupCard({
    required this.group,
    required this.index,
    required this.totalGroups,
    required this.maxItems,
    required this.busy,
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
  final int maxItems;
  final bool busy;
  final Future<void> Function(String groupId, String subtitle) onRenameGroup;
  final Future<void> Function(String groupId, int delta) onMoveGroup;
  final Future<void> Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddItemRequested;
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String description)
  onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemState = group.items.length > maxItems
        ? TenantAdminGalleryCapacityState.overLimit
        : group.items.length == maxItems
        ? TenantAdminGalleryCapacityState.atLimit
        : TenantAdminGalleryCapacityState.available;

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
                  onFieldSubmitted: (value) =>
                      unawaited(onRenameGroup(group.groupId, value)),
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
                    onPressed: busy || index == 0
                        ? null
                        : () => unawaited(onMoveGroup(group.groupId, -1)),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Mover para baixo',
                    onPressed: busy || index >= totalGroups - 1
                        ? null
                        : () => unawaited(onMoveGroup(group.groupId, 1)),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Remover grupo',
                    onPressed: busy
                        ? null
                        : () => unawaited(onRemoveGroup(group.groupId)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (group.items.isEmpty)
            Text(
              'Esta galeria está vazia e será ignorada no perfil público.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (
                  var itemIndex = 0;
                  itemIndex < group.items.length;
                  itemIndex++
                ) ...[
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
          if (itemState == TenantAdminGalleryCapacityState.overLimit) ...[
            const SizedBox(height: 8),
            Text(
              'Remova pelo menos ${group.items.length - maxItems} '
              '${group.items.length - maxItems == 1 ? 'item' : 'itens'} '
              'para voltar ao limite do plano.',
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: Key('tenantAdminGalleryGroupAddItem_${group.groupId}'),
            onPressed:
                busy || itemState != TenantAdminGalleryCapacityState.available
                ? null
                : () => unawaited(onAddItemRequested(group.groupId)),
            icon: const Icon(Icons.add_to_photos_outlined),
            label: Text(
              'Adicionar item · ${group.items.length} / $maxItems '
              '${itemState == TenantAdminGalleryCapacityState.overLimit ? '(acima do plano)' : ''}',
            ),
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
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String description)
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
                    labelText: 'Descrição do item',
                    hintText: 'Opcional',
                  ),
                  onFieldSubmitted: (value) => unawaited(
                    onDescriptionChanged(groupId, item.itemId, value),
                  ),
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
                      icon: Icon(
                        item.type ==
                                TenantAdminAccountProfileGalleryItemType.photo
                            ? Icons.image_search_outlined
                            : Icons.video_library_outlined,
                      ),
                      label: Text(
                        item.type ==
                                TenantAdminAccountProfileGalleryItemType.photo
                            ? 'Trocar foto'
                            : 'Trocar vídeo',
                      ),
                    ),
                    if (totalItems > 1)
                      IconButton(
                        tooltip: 'Mover para cima',
                        onPressed: index == 0
                            ? null
                            : () => unawaited(
                                onMoveItem(groupId, item.itemId, -1),
                              ),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    if (totalItems > 1)
                      IconButton(
                        tooltip: 'Mover para baixo',
                        onPressed: index >= totalItems - 1
                            ? null
                            : () => unawaited(
                                onMoveItem(groupId, item.itemId, 1),
                              ),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    IconButton(
                      tooltip: 'Remover foto',
                      onPressed: () =>
                          unawaited(onRemoveItem(groupId, item.itemId)),
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
      child: Icon(
        item.type == TenantAdminAccountProfileGalleryItemType.photo
            ? Icons.image_outlined
            : Icons.play_circle_outline,
      ),
    );
  }
}
