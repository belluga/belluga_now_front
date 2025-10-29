import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/view_models/upcoming_event_data.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:belluga_now/presentation/view_models/favorite_item_data.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_item.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorite_chip.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/invites_banner.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key});

  // --- MOCK DATA ---
  static const List<FavoriteItemData> _favorites = [
    FavoriteItemData(icon: Icons.location_pin, isPrimary: true),
    FavoriteItemData(icon: Icons.restaurant_menu),
    FavoriteItemData(icon: Icons.event),
    FavoriteItemData(icon: Icons.local_offer),
    FavoriteItemData(icon: Icons.child_friendly),
  ];

  static const List<EventCardData> _carouselEvents = [
    EventCardData(
      title: 'Festival de Verão',
      subtitle: 'Praia do Morro - Hoje, 20h',
    ),
    EventCardData(
      title: 'Luau Exclusivo',
      subtitle: 'Areia Preta - Amanhã, 22h',
    ),
    EventCardData(
      title: 'Sunset Experience',
      subtitle: 'Parque da Areia - Domingo, 18h',
    ),
  ];

  static const List<UpcomingEventData> _upcomingEvents = [
    UpcomingEventData(
      title: 'Circuito Gastronômico',
      category: 'Chef Table',
      price: '\$\$',
      distance: '1,2 km',
      rating: 5,
      description: 'Sabores autorais servidos em sequencia exclusiva.',
    ),
    UpcomingEventData(
      title: 'Passeio de Escuna',
      category: 'Experiência',
      price: '\$\$',
      distance: '800 m',
      rating: 4,
      description: 'Três paradas para mergulho com guia local.',
    ),
    UpcomingEventData(
      title: 'Tour Histórico a Pé',
      category: 'Cultura',
      price: '\$',
      distance: '2 km',
      rating: 4,
      description: 'Descubra os segredos e histórias do centro.',
    ),
  ];
  // --- END MOCK DATA ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16, // Adjusted padding
        title: Row(
          children: [
            Icon(Icons.location_pin, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Guarappari',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        child: const Icon(Icons.location_pin),
      ),
      bottomNavigationBar: BellugaBottomNavigationBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Seus Favoritos',
                onPressed: () {},
              ),
              SizedBox(
                height: 90, // Adjusted height to fit new radius
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _favorites.length,
                  clipBehavior: Clip.none, // Allow shadows to render
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _favorites[index];
                    return FavoriteChip(item: item);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // --- INVITES BANNER ---
              InvitesBanner(onPressed: () {}),
              const SizedBox(height: 16),

              // --- SEUS EVENTOS ---
              SectionHeader(
                title: 'Seus Eventos',
                onPressed: () {},
              ),
              SizedBox(
                height: 180, // Height of the carousel
                child: CarouselView.weighted(
                  flexWeights: const [1, 5, 1], // Hero layout
                  // itemSnapping: true,
                  children: _carouselEvents
                      .map((event) => CarouselEventCard(data: event))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // --- PRÓXIMOS EVENTOS ---
              SectionHeader(
                title: 'Próximos Eventos',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _upcomingEvents.length,
                // Using a taller separator to match the design
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final event = _upcomingEvents[index];
                  return UpcomingEventItem(data: event);
                },
              ),
              const SizedBox(height: 150), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}