import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/models/menu_section.dart';
import 'package:flutter/material.dart';

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.action,
    this.showDivider = true,
  });

  final MenuAction action;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = ListTile(
      onTap: action.onTap,
      leading: Icon(action.icon, color: theme.colorScheme.primary),
      title: Text(
        action.label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        action.helper,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (!showDivider) {
      return tile;
    }

    return Column(
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 0,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
