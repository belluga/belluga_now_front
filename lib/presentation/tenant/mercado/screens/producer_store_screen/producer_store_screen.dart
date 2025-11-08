import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/controllers/producer_store_controller.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/widgets/producer_about_section.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/widgets/producer_gallery_section.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/widgets/producer_hero_section.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/widgets/producer_products_section.dart';
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
          ProducerHeroSection(
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
                  ProducerProductsSection(products: widget.producer.products),
                if (widget.producer.products.isNotEmpty)
                  const SizedBox(height: 32),
                if (widget.producer.about.isNotEmpty)
                  ProducerAboutSection(
                    name: widget.producer.name,
                    about: widget.producer.about,
                  ),
                if (widget.producer.about.isNotEmpty)
                  const SizedBox(height: 32),
                if (widget.producer.galleryImages.isNotEmpty)
                  ProducerGallerySection(images: widget.producer.galleryImages),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
