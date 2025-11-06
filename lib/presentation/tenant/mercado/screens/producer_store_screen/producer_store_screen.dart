import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/controllers/producer_store_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ProducerStoreScreen extends StatefulWidget {
  const ProducerStoreScreen({super.key, required this.producer});

  final MercadoProducer producer;

  @override
  State<ProducerStoreScreen> createState() => _ProducerStoreScreenState();
}

class _ProducerStoreScreenState extends State<ProducerStoreScreen> {
  late final ProducerStoreController _controller =
      ProducerStoreController(producer: widget.producer);

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      floatingActionButton: StreamValueBuilder<bool>(
        streamValue: _controller.isFollowingStreamValue,
        builder: (context, isFollowing) {
          return FloatingActionButton.extended(
            onPressed: _controller.toggleFollow,
            icon: Icon(isFollowing ? Icons.check : Icons.favorite_border),
            label: Text(isFollowing ? 'Apoiando' : 'Apoiar'),
          );
        },
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroSection(
            producer: widget.producer,
            height: heroHeight,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producer.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.producer.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.producer.whatsappNumber != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.whatshot),
                    label: const Text('Falar no WhatsApp'),
                  ),
                ],
                const SizedBox(height: 24),
                if (widget.producer.products.isNotEmpty)
                  _ProductsSection(products: widget.producer.products),
                if (widget.producer.products.isNotEmpty)
                  const SizedBox(height: 32),
                if (widget.producer.about.isNotEmpty)
                  _AboutSection(
                    name: widget.producer.name,
                    about: widget.producer.about,
                  ),
                if (widget.producer.about.isNotEmpty)
                  const SizedBox(height: 32),
                if (widget.producer.galleryImages.isNotEmpty)
                  _GallerySection(images: widget.producer.galleryImages),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
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

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.products});

  final List<MercadoProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nossos Produtos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 220,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: FilledButton.tonal(
                          onPressed: () {},
                          child: const Text('Ver Detalhes'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.name, required this.about});

  final String name;
  final String about;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre $name',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          about,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeria',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
