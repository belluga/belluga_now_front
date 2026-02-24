import 'package:flutter/material.dart';

class ProfileEditableTile extends StatelessWidget {
  const ProfileEditableTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      subtitle: Text(
        value.isEmpty ? 'Toque para preencher' : value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: value.isEmpty
              ? colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt())
              : colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
