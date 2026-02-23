import 'package:flutter/material.dart';

class TenantAdminShellHeader extends StatelessWidget {
  const TenantAdminShellHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const <String>[],
    this.showBackButton = false,
    this.onBack,
    required this.tenantLabel,
    required this.canChangeTenant,
    required this.onChangeTenant,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final List<String> breadcrumbs;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String tenantLabel;
  final bool canChangeTenant;
  final VoidCallback onChangeTenant;
  final List<Widget> actions;

  Widget _buildBreadcrumbs(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        for (var i = 0; i < breadcrumbs.length; i++) ...[
          if (i > 0)
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
          Text(
            breadcrumbs[i],
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              key: const ValueKey('tenant_admin_shell_header_back'),
              tooltip: 'Voltar',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin landlord',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (breadcrumbs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildBreadcrumbs(context),
                ],
                const SizedBox(height: 6),
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 12),
          Semantics(
            identifier: 'tenant_admin_shell_change_tenant_button',
            button: true,
            onTap: canChangeTenant ? onChangeTenant : null,
            child: FilledButton.tonalIcon(
              key: const ValueKey('tenant_admin_shell_change_tenant'),
              onPressed: canChangeTenant ? onChangeTenant : null,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(
                tenantLabel,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
