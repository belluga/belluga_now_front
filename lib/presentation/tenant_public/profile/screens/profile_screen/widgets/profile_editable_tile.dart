import 'package:flutter/material.dart';

class ProfileEditableTile extends StatelessWidget {
  const ProfileEditableTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.readOnly = false,
    this.emptyValueLabel = 'Toque para preencher',
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool readOnly;
  final String emptyValueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      subtitle: Text(
        value.isEmpty ? emptyValueLabel : value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: value.isEmpty
              ? colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt())
              : colorScheme.onSurface,
        ),
      ),
      trailing: Icon(readOnly ? Icons.lock_outline : Icons.chevron_right),
      onTap: onTap,
    );
  }
}
