import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:belluga_now/presentation/view_models/favorite_item_data.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorites_strip.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/invites_banner.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';

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

  List<EventCardData> get _carouselEvents => [
        EventCardData(
          title: 'Festival de Verão',
          imageUrl:
              'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=800',
          startDateTime: DateTime(2024, 1, 7, 20, 0),
          location: 'Praia do Morro',
          artist: 'DJ Mare Alta',
        ),
        EventCardData(
          title: 'Luau Exclusivo',
          imageUrl:
              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
          startDateTime: DateTime(2024, 1, 8, 22, 0),
          location: 'Areia Preta',
          artist: 'Banda Eclipse',
        ),
        EventCardData(
          title: 'Sunset Experience',
          imageUrl:
              'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
          startDateTime: DateTime(2024, 1, 9, 18, 0),
          location: 'Parque da Areia',
          artist: 'DJ Horizonte',
        ),
      ];

  List<EventCardData> get _upcomingEvents => [
        EventCardData(
          title: 'Circuito Gastronomico',
          imageUrl:
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
          startDateTime: DateTime(2024, 1, 12, 19, 30),
          location: 'Bistro da Orla',
          artist: 'Chef Paula Figueiredo',
        ),
        EventCardData(
          title: 'Passeio de Escuna',
          imageUrl:
              'https://images.unsplash.com/photo-1493558103817-58b2924bce98?w=800',
          startDateTime: DateTime(2024, 1, 13, 9, 0),
          location: 'Porto da Barra',
          artist: 'Guia Clara Nunes',
        ),
        EventCardData(
          title: 'Tour Historico a Pe',
          imageUrl:
              'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
          startDateTime: DateTime(2024, 1, 14, 15, 0),
          location: 'Centro Historico',
          artist: 'Historiador Joao Mendes',
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Seus Favoritos',
                onPressed: () {},
              ),
              FavoritesStrip(
                items: _favorites,
                pinFirst: true,
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
                height: MediaQuery.of(context).size.width * 0.8 * 9 / 16,
                child: CarouselView(
                  itemExtent: MediaQuery.of(context).size.width * 0.8,
                  itemSnapping: true,
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
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final event = _upcomingEvents[index];
                  return UpcomingEventCard(data: event);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
