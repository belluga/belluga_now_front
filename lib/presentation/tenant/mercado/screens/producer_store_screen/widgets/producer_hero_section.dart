import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:flutter/material.dart';

class ProducerHeroSection extends StatelessWidget {
  const ProducerHeroSection({
    super.key,
    required this.producer,
    required this.height,
  });

  final MercadoProducer producer;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Image.network(
                producer.heroImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => context.router.maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(producer.logoImageUrl),
              backgroundColor: theme.colorScheme.surface,
              onBackgroundImageError: (_, __) {},
              child: producer.logoImageUrl.isEmpty
                  ? Text(
                      producer.name.characters.first.toUpperCase(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
