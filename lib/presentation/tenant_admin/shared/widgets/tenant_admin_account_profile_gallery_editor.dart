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
    required this.operationError,
    required this.resolveInputValue,
    required this.onInputChanged,
    required this.onAddGroup,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onAddPhotoRequested,
    required this.onAddYoutubeRequested,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  final List<TenantAdminAccountProfileGalleryGroupDraft> groups;
  final int maxGroups;
  final int maxItemsPerGallery;
  final bool busy;
  final Map<String, String> fieldErrors;
  final String? operationError;
  final String Function(String fieldPath, String authoritativeValue)
  resolveInputValue;
  final void Function(String fieldPath, String value) onInputChanged;
  final Future<void> Function() onAddGroup;
  final Future<void> Function(String groupId, String subtitle) onRenameGroup;
  final Future<void> Function(String groupId, int delta) onMoveGroup;
  final Future<void> Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddPhotoRequested;
  final Future<void> Function(String groupId) onAddYoutubeRequested;
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String title)
  onTitleChanged;
  final Future<void> Function(String groupId, String itemId, String description)
  onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final galleryState = _capacityState(groups.length, maxGroups);
    final createGroupError = fieldErrors['group.create.subtitle'];
    final sectionErrors = fieldErrors.entries
        .where((entry) => !entry.key.startsWith('group.'))
        .map((entry) => entry.value)
        .toList(growable: false);

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
          if (sectionErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              sectionErrors.join('\n'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (operationError case final message?) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('tenantAdminGalleryOperationError'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
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
              fieldErrors: fieldErrors,
              resolveInputValue: resolveInputValue,
              onInputChanged: onInputChanged,
              onRenameGroup: onRenameGroup,
              onMoveGroup: onMoveGroup,
              onRemoveGroup: onRemoveGroup,
              onAddPhotoRequested: onAddPhotoRequested,
              onAddYoutubeRequested: onAddYoutubeRequested,
              onReplaceItemRequested: onReplaceItemRequested,
              onMoveItem: onMoveItem,
              onRemoveItem: onRemoveItem,
              onTitleChanged: onTitleChanged,
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
          if (createGroupError != null) ...[
            const SizedBox(height: 6),
            Text(
              createGroupError,
              key: const Key('tenantAdminGalleryCreateGroupError'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
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
    required this.fieldErrors,
    required this.resolveInputValue,
    required this.onInputChanged,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onAddPhotoRequested,
    required this.onAddYoutubeRequested,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  final TenantAdminAccountProfileGalleryGroupDraft group;
  final int index;
  final int totalGroups;
  final int maxItems;
  final bool busy;
  final Map<String, String> fieldErrors;
  final String Function(String fieldPath, String authoritativeValue)
  resolveInputValue;
  final void Function(String fieldPath, String value) onInputChanged;
  final Future<void> Function(String groupId, String subtitle) onRenameGroup;
  final Future<void> Function(String groupId, int delta) onMoveGroup;
  final Future<void> Function(String groupId) onRemoveGroup;
  final Future<void> Function(String groupId) onAddPhotoRequested;
  final Future<void> Function(String groupId) onAddYoutubeRequested;
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String title)
  onTitleChanged;
  final Future<void> Function(String groupId, String itemId, String description)
  onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupErrorPrefix = 'group.${group.groupId}';
    final createItemErrorPrefix = '$groupErrorPrefix.item.create';
    final groupSubtitleError = fieldErrors['$groupErrorPrefix.subtitle'];
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
          Text(
            'Galeria ${index + 1}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: Key(
                        'tenantAdminGalleryGroupSubtitle_${group.groupId}',
                      ),
                      initialValue: resolveInputValue(
                        '$groupErrorPrefix.subtitle',
                        group.subtitle,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nome da galeria',
                      ),
                      onFieldSubmitted: (value) =>
                          unawaited(onRenameGroup(group.groupId, value)),
                      onChanged: (value) =>
                          onInputChanged('$groupErrorPrefix.subtitle', value),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subtítulo obrigatório.';
                        }
                        return null;
                      },
                    ),
                    if (groupSubtitleError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        groupSubtitleError,
                        key: Key(
                          'tenantAdminGalleryGroupSubtitleError_${group.groupId}',
                        ),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ],
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
                    fieldErrors: fieldErrors,
                    resolveInputValue: resolveInputValue,
                    onInputChanged: onInputChanged,
                    onReplaceItemRequested: onReplaceItemRequested,
                    onMoveItem: onMoveItem,
                    onRemoveItem: onRemoveItem,
                    onTitleChanged: onTitleChanged,
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
          Text(
            '${group.items.length} / $maxItems itens · ${switch (itemState) {
              TenantAdminGalleryCapacityState.available => 'disponível',
              TenantAdminGalleryCapacityState.atLimit => 'no limite do plano',
              TenantAdminGalleryCapacityState.overLimit => 'acima do limite do plano',
            }}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('tenantAdminGalleryGroupAddPhoto_${group.groupId}'),
                  onPressed:
                      busy ||
                          itemState != TenantAdminGalleryCapacityState.available
                      ? null
                      : () => unawaited(onAddPhotoRequested(group.groupId)),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Adicionar foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: Key(
                    'tenantAdminGalleryGroupAddYoutube_${group.groupId}',
                  ),
                  onPressed:
                      busy ||
                          itemState != TenantAdminGalleryCapacityState.available
                      ? null
                      : () => unawaited(onAddYoutubeRequested(group.groupId)),
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Adicionar vídeo'),
                ),
              ),
            ],
          ),
          if (fieldErrors['$createItemErrorPrefix.image'] != null ||
              fieldErrors['$createItemErrorPrefix.youtube_url'] != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    fieldErrors['$createItemErrorPrefix.image'] ?? '',
                    key: Key(
                      'tenantAdminGalleryGroupAddPhotoError_${group.groupId}',
                    ),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fieldErrors['$createItemErrorPrefix.youtube_url'] ?? '',
                    key: Key(
                      'tenantAdminGalleryGroupAddYoutubeError_${group.groupId}',
                    ),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
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
    required this.fieldErrors,
    required this.resolveInputValue,
    required this.onInputChanged,
    required this.onReplaceItemRequested,
    required this.onMoveItem,
    required this.onRemoveItem,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  final String groupId;
  final TenantAdminAccountProfileGalleryItemDraft item;
  final int index;
  final int totalItems;
  final Map<String, String> fieldErrors;
  final String Function(String fieldPath, String authoritativeValue)
  resolveInputValue;
  final void Function(String fieldPath, String value) onInputChanged;
  final Future<void> Function(String groupId, String itemId)
  onReplaceItemRequested;
  final Future<void> Function(String groupId, String itemId, int delta)
  onMoveItem;
  final Future<void> Function(String groupId, String itemId) onRemoveItem;
  final Future<void> Function(String groupId, String itemId, String title)
  onTitleChanged;
  final Future<void> Function(String groupId, String itemId, String description)
  onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final errorPrefix = 'group.$groupId.item.${item.itemId}';
    final providerError =
        fieldErrors['$errorPrefix.${item.type == TenantAdminAccountProfileGalleryItemType.photo ? 'image' : 'youtube_url'}'];
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
                Text(
                  '${index + 1}. ${item.type == TenantAdminAccountProfileGalleryItemType.photo ? 'FOTO' : 'VÍDEO DO YOUTUBE'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                _AuthoritativeGalleryTextField(
                  fieldKey: Key('tenantAdminGalleryItemTitle_${item.itemId}'),
                  authoritativeSnapshot: item,
                  value: resolveInputValue(
                    '$errorPrefix.title',
                    item.title ?? '',
                  ),
                  maxLength: 255,
                  labelText: 'Título do item',
                  errorText: fieldErrors['$errorPrefix.title'],
                  errorKey: Key(
                    'tenantAdminGalleryItemTitleError_${item.itemId}',
                  ),
                  onSubmitted: (value) =>
                      unawaited(onTitleChanged(groupId, item.itemId, value)),
                  onChanged: (value) =>
                      onInputChanged('$errorPrefix.title', value),
                ),
                const SizedBox(height: 6),
                _AuthoritativeGalleryTextField(
                  fieldKey: Key(
                    'tenantAdminGalleryItemDescription_${item.itemId}',
                  ),
                  authoritativeSnapshot: item,
                  value: resolveInputValue(
                    '$errorPrefix.description',
                    item.description ?? '',
                  ),
                  maxLines: 2,
                  labelText: 'Descrição do item',
                  errorText: fieldErrors['$errorPrefix.description'],
                  errorKey: Key(
                    'tenantAdminGalleryItemDescriptionError_${item.itemId}',
                  ),
                  onSubmitted: (value) => unawaited(
                    onDescriptionChanged(groupId, item.itemId, value),
                  ),
                  onChanged: (value) =>
                      onInputChanged('$errorPrefix.description', value),
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
                      tooltip:
                          item.type ==
                              TenantAdminAccountProfileGalleryItemType.photo
                          ? 'Remover foto'
                          : 'Remover vídeo',
                      onPressed: () =>
                          unawaited(onRemoveItem(groupId, item.itemId)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                if (providerError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    providerError,
                    key: Key(
                      'tenantAdminGalleryItemProviderError_${item.itemId}',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthoritativeGalleryTextField extends StatelessWidget {
  const _AuthoritativeGalleryTextField({
    required this.fieldKey,
    required this.authoritativeSnapshot,
    required this.value,
    required this.labelText,
    required this.onSubmitted,
    required this.onChanged,
    this.errorText,
    this.errorKey,
    this.maxLength,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final Object authoritativeSnapshot;
  final String value;
  final String labelText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final Key? errorKey;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: ValueKey((authoritativeSnapshot, fieldKey)),
          child: TextFormField(
            key: fieldKey,
            initialValue: value,
            maxLength: maxLength,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: 'Opcional',
            ),
            onFieldSubmitted: onSubmitted,
            onChanged: onChanged,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            key: errorKey,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
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
