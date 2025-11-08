import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:flutter/material.dart';

class ProducerCard extends StatelessWidget {
  const ProducerCard({
    super.key,
    required this.producer,
    required this.onTap,
    required this.categoryResolver,
  });

  final MercadoProducer producer;
  final VoidCallback onTap;
  final MercadoCategory? Function(String) categoryResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryIcons = producer.categories
        .map(categoryResolver)
        .whereType<MercadoCategory>()
        .map((category) => category.icon)
        .toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(producer.logoImageUrl),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    onBackgroundImageError: (_, __) {},
                    child: producer.logoImageUrl.isEmpty
                        ? Text(
                            producer.name.characters.first.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producer.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          producer.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    tooltip: 'Abrir produtor',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                producer.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: categoryIcons
                    .map(
                      (icon) => Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
