import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/partners/controllers/partner_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final _controller = GetIt.I.get<PartnerDetailController>();

  @override
  void initState() {
    super.initState();
    _controller.loadPartner(widget.slug);
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamValueBuilder<bool>(
        streamValue: _controller.isLoadingStreamValue,
        builder: (context, isLoading) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamValueBuilder<PartnerModel?>(
            streamValue: _controller.partnerStreamValue,
            builder: (context, partner) {
              if (partner == null) {
                return const Center(
                  child: Text('Parceiro não encontrado'),
                );
              }

              return _buildPartnerDetail(partner);
            },
          );
        },
      ),
    );
  }

  Widget _buildPartnerDetail(PartnerModel partner) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = _controller.isFavorite(partner.id);

    return CustomScrollView(
      slivers: [
        // Cover image with back button and favorite
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: partner.coverUrl != null
                ? Image.network(
                    partner.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          partner.type == PartnerType.artist
                              ? Icons.person
                              : Icons.place,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      partner.type == PartnerType.artist
                          ? Icons.person
                          : Icons.place,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null,
              ),
              onPressed: () {
                setState(() {
                  _controller.toggleFavorite(partner.id);
                });
              },
            ),
          ],
        ),
        // Partner content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar (if different from cover)
                if (partner.avatarUrl != null &&
                    partner.avatarUrl != partner.coverUrl)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(partner.avatarUrl!),
                    ),
                  ),
                if (partner.avatarUrl != null &&
                    partner.avatarUrl != partner.coverUrl)
                  const SizedBox(height: 16),
                // Name
                Text(
                  partner.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                // Type
                Text(
                  partner.type == PartnerType.artist
                      ? 'Artista'
                      : partner.type == PartnerType.venue
                          ? 'Local'
                          : 'Provedor de Experiências',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                // Bio
                if (partner.bio != null) ...[
                  Text(
                    partner.bio!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                // Tags
                if (partner.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: partner.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: colorScheme.secondaryContainer,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                // Upcoming events section
                Text(
                  'Próximos Eventos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (partner.upcomingEventIds.isEmpty)
                  const Text('Nenhum evento próximo')
                else
                  Text(
                    '${partner.upcomingEventIds.length} eventos próximos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                // TODO: Display actual event cards here
              ],
            ),
          ),
        ),
      ],
    );
  }
}
