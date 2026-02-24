import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/models/menu_section.dart';
import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/widgets/menu_tile.dart';
import 'package:flutter/material.dart';

class MenuSectionCard extends StatelessWidget {
  const MenuSectionCard({super.key, required this.section});

  final MenuSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (int i = 0; i < section.actions.length; i++)
                MenuTile(
                  action: section.actions[i],
                  showDivider: i != section.actions.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
