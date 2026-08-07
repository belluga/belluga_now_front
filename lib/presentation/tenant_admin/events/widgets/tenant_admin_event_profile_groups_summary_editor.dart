import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';

class TenantAdminEventProfileGroupsSummaryEditor extends StatelessWidget {
  const TenantAdminEventProfileGroupsSummaryEditor({
    super.key,
    required this.keyPrefix,
    required this.groups,
    required this.addButtonKey,
    required this.onAddGroup,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    this.onManageGroup,
    this.manageBlockedReasonBuilder,
    this.title = 'Abas de perfis relacionados',
    this.emptyText = 'Nenhum grupo configurado.',
  });

  final String keyPrefix;
  final List<TenantAdminNestedProfileGroup> groups;
  final Key addButtonKey;
  final VoidCallback onAddGroup;
  final void Function(String groupId, String label) onRenameGroup;
  final void Function(String groupId, int delta) onMoveGroup;
  final ValueChanged<String> onRemoveGroup;
  final Future<void> Function(TenantAdminNestedProfileGroup group)?
  onManageGroup;
  final String Function(TenantAdminNestedProfileGroup group)?
  manageBlockedReasonBuilder;
  final String title;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return TenantAdminFormSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groups.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodySmall),
          for (var index = 0; index < groups.length; index++) ...[
            _TenantAdminEventProfileGroupSummaryCard(
              keyPrefix: keyPrefix,
              group: groups[index],
              index: index,
              total: groups.length,
              onRenameGroup: onRenameGroup,
              onMoveGroup: onMoveGroup,
              onRemoveGroup: onRemoveGroup,
              onManageGroup: onManageGroup,
              manageBlockedReasonBuilder: manageBlockedReasonBuilder,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            key: addButtonKey,
            onPressed: groups.length >= 12 ? null : onAddGroup,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar grupo'),
          ),
        ],
      ),
    );
  }
}

class _TenantAdminEventProfileGroupSummaryCard extends StatelessWidget {
  const _TenantAdminEventProfileGroupSummaryCard({
    required this.keyPrefix,
    required this.group,
    required this.index,
    required this.total,
    required this.onRenameGroup,
    required this.onMoveGroup,
    required this.onRemoveGroup,
    required this.onManageGroup,
    required this.manageBlockedReasonBuilder,
  });

  final String keyPrefix;
  final TenantAdminNestedProfileGroup group;
  final int index;
  final int total;
  final void Function(String groupId, String label) onRenameGroup;
  final void Function(String groupId, int delta) onMoveGroup;
  final ValueChanged<String> onRemoveGroup;
  final Future<void> Function(TenantAdminNestedProfileGroup group)?
  onManageGroup;
  final String Function(TenantAdminNestedProfileGroup group)?
  manageBlockedReasonBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final blockedReason = manageBlockedReasonBuilder?.call(group).trim() ?? '';
    final canManage = onManageGroup != null && blockedReason.isEmpty;

    return Container(
      key: Key('${keyPrefix}ProfileGroup_${group.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('${keyPrefix}ProfileGroupLabel_${group.id}'),
                  initialValue: group.label,
                  decoration: const InputDecoration(labelText: 'Nome da aba'),
                  onChanged: (value) => onRenameGroup(group.id, value),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome da aba e obrigatorio.';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Mover para cima',
                onPressed: index == 0 ? null : () => onMoveGroup(group.id, -1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Mover para baixo',
                onPressed: index >= total - 1
                    ? null
                    : () => onMoveGroup(group.id, 1),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: 'Remover grupo',
                onPressed: () => onRemoveGroup(group.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.memberCount == 1
                ? '1 perfil vinculado'
                : '${group.memberCount} perfis vinculados',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: blockedReason,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: Key('${keyPrefix}ManageGroup_${group.id}'),
                onPressed: canManage ? () => onManageGroup!(group) : null,
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Gerenciar perfis'),
              ),
            ),
          ),
          if (blockedReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              blockedReason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
