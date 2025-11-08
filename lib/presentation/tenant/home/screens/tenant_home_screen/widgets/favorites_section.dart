import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorites_strip.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSection extends StatelessWidget {
  const FavoritesSection({
    super.key,
    required this.controller,
  });

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<FavoriteResume>?>(
      streamValue: controller.favoritesStreamValue,
      onNullWidget: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, favorites) {
        final items = favorites ?? const <FavoriteResume>[];
        if (items.isEmpty) {
          return const EmptyFavoritesState();
        }
        return FavoritesStrip(items: items, pinFirst: true);
      },
    );
  }
}

class EmptyFavoritesState extends StatelessWidget {
  const EmptyFavoritesState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 118,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Nenhum favorito ainda.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
