//
// home_screen.dart
//
// Foundational implementation of the Home Screen, adjusted to perfectly match
// the M3 design specification from the screenshot.
//

import 'package:flutter/material.dart';

// -------------------------------------------------------------------
// DATA CLASSES (Adjusted for Design)
// -------------------------------------------------------------------

class _FavoriteItem {
  const _FavoriteItem({
    required this.title,
    required this.icon,
    this.isPrimary = false,
  });

  final String title;
  final IconData icon;
  final bool isPrimary;
}

class _EventCardData {
  const _EventCardData({
    required this.title,
    required this.subtitle,
    required this.colorSeed,
  });

  final String title;
  final String subtitle;
  final Color colorSeed;
}

class _UpcomingEventData {
  const _UpcomingEventData({
    required this.title,
    required this.category,
    required this.price, // Added
    required this.distance, // Added
    required this.rating,
    required this.description,
  });

  final String title;
  final String category;
  final String price;
  final String distance;
  final int rating;
  final String description;
}

// -------------------------------------------------------------------
// HOME SCREEN WIDGET
// -------------------------------------------------------------------

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key});

  // --- MOCK DATA ---
  static const List<_FavoriteItem> _favorites = [
    _FavoriteItem(title: 'Meu Local', icon: Icons.location_pin, isPrimary: true),
    _FavoriteItem(title: 'Gastronomia', icon: Icons.restaurant_menu),
    _FavoriteItem(title: 'Eventos', icon: Icons.event),
    _FavoriteItem(title: 'Promoções', icon: Icons.local_offer),
    _FavoriteItem(title: 'Kids', icon: Icons.child_friendly),
  ];

  static const List<_EventCardData> _carouselEvents = [
    _EventCardData(
      title: 'Festival de Verão',
      subtitle: 'Praia do Morro - Hoje, 20h',
      colorSeed: Colors.deepPurple,
    ),
    _EventCardData(
      title: 'Luau Exclusivo',
      subtitle: 'Areia Preta - Amanhã, 22h',
      colorSeed: Colors.teal,
    ),
    _EventCardData(
      title: 'Sunset Experience',
      subtitle: 'Parque da Areia - Domingo, 18h',
      colorSeed: Colors.orange,
    ),
  ];

  static const List<_UpcomingEventData> _upcomingEvents = [
    _UpcomingEventData(
      title: 'Circuito Gastronômico',
      category: 'Chef Table',
      price: '\$\$',
      distance: '1,2 km',
      rating: 5,
      description: 'Sabores autorais servidos em sequencia exclusiva.',
    ),
    _UpcomingEventData(
      title: 'Passeio de Escuna',
      category: 'Experiência',
      price: '\$\$',
      distance: '800 m',
      rating: 4,
      description: 'Três paradas para mergulho com guia local.',
    ),
    _UpcomingEventData(
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
      // --- APP BAR ---
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

      // --- FAB & BOTTOM NAV ---
      // This implementation matches the screenshot's notched design (M2 style)
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.location_pin),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavIcon(
              icon: Icons.add,
              label: 'Início',
              isSelected: true,
              onPressed: () {},
            ),
            _BottomNavIcon(
              icon: Icons.calendar_month,
              label: 'Agenda',
              onPressed: () {},
            ),
            const SizedBox(width: 48), // The space for the FAB
            _BottomNavIcon(
              icon: Icons.add_box_outlined, // Using outlined for non-selected
              label: 'Experiências',
              onPressed: () {},
            ),
            _BottomNavIcon(
              icon: Icons.menu,
              label: 'Menu',
              onPressed: () {},
            ),
          ],
        ),
      ),
      // --- END FAB & BOTTOM NAV ---

      body: SafeArea(
        child: SingleChildScrollView(
          // Adjusted padding to match the design's wider content
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEUS FAVORITOS ---
              _SectionHeader(
                title: 'Seus Favoritos',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 108, // Adjusted height to fit new radius
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _favorites.length,
                  clipBehavior: Clip.none, // Allow shadows to render
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _favorites[index];
                    return _FavoriteChip(item: item);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- INVITES BANNER ---
              _InvitesBanner(onPressed: () {}),
              const SizedBox(height: 32),

              // --- SEUS EVENTOS ---
              _SectionHeader(
                title: 'Seus Eventos',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240, // Height of the carousel
                child: CarouselView.weighted(
                  flexWeights: const [1, 5, 1], // Hero layout
                  itemSnapping: true,
                  children: _carouselEvents
                      .map((event) => _CarouselEventCard(data: event))
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),

              // --- PRÓXIMOS EVENTOS ---
              _SectionHeader(
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
                  return _UpcomingEventItem(data: event);
                },
              ),
              const SizedBox(height: 96), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _BottomNavIcon
// -------------------------------------------------------------------
// Helper widget for the BottomAppBar
class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _SectionHeader
// -------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            // Adjusted style to match design's hierarchy
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Ver mais',
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _FavoriteChip
// -------------------------------------------------------------------
class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({required this.item});

  final _FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color backgroundColor =
        item.isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final Color foregroundColor =
        item.isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return Column(
      // Aligned to center
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36, // Increased radius
          backgroundColor: backgroundColor,
          child: Icon(
            item.icon,
            color: foregroundColor,
            size: 28,
          ),
        ),
        const SizedBox(height: 8), // Added spacing
        SizedBox(
          width: 72,
          child: Text(
            item.title,
            style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _InvitesBanner
// -------------------------------------------------------------------
class _InvitesBanner extends StatelessWidget {
  const _InvitesBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // This widget was well-implemented. No changes needed.
    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Você tem 3 convites pendentes...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onTertiaryContainer,
                shape: const StadiumBorder(),
              ),
              child: const Text('Bora?'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _CarouselEventCard
// -------------------------------------------------------------------
class _CarouselEventCard extends StatelessWidget {
  const _CarouselEventCard({required this.data});

  final _EventCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // This color logic is great.
    final Color baseTint = data.colorSeed.withAlpha((0.35 * 255).round());
    final Color backgroundColor =
        Color.alphaBlend(baseTint, colorScheme.surfaceContainerHighest);
    final Color supportingColor = colorScheme.onSurfaceVariant;

    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Added Expanded placeholder to match screenshot's visual-first layout
            Expanded(
              child: Center(
                child: Icon(
                  Icons.confirmation_num_outlined, // Placeholder icon
                  size: 64,
                  color: supportingColor.withOpacity(0.6),
                ),
              ),
            ),
            // Kept your data-driven text
            Text(
              data.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: supportingColor),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: _UpcomingEventItem
// -------------------------------------------------------------------
// Re-implemented as a flat Row, not a Card, to match the design
class _UpcomingEventItem extends StatelessWidget {
  const _UpcomingEventItem({required this.data});

  final _UpcomingEventData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Thumbnail ---
        ClipRRect(
          borderRadius: BorderRadius.circular(12), // M3 standard
          child: Container(
            height: 80, // Increased size
            width: 80, // Increased size
            color: colorScheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_outlined, // Changed to outline
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // --- Text Content ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              // Sub-header built from adjusted data model
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  children: [
                    TextSpan(text: data.category),
                    TextSpan(text: ' • ${data.price}'),
                    TextSpan(text: ' • ${data.distance}'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Rating stars
              Wrap(
                spacing: 2,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < data.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // --- Favorite Icon ---
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border),
          tooltip: 'Favoritar',
        ),
      ],
    );
  }
}