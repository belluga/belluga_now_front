import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/home_upcoming_events_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorites_strip.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:belluga_now/presentation/view_models/favorite_item_data.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  late final TenantHomeController _controller =
      GetIt.I.get<TenantHomeController>();
  late final HomeUpcomingEventsController _upcomingController =
      GetIt.I.get<HomeUpcomingEventsController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
    _upcomingController.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
    _upcomingController.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificacoes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: const FloatingActionButtonCustom(),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
      body: SafeArea(
        child: StreamValueBuilder<HomeOverview?>(
          streamValue: _controller.overviewStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, overview) {
            if (overview == null) {
              return const SizedBox.shrink();
            }
            return _buildContent(context, overview);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeOverview overview) {
    final favorites =
        overview.favorites.map(_mapFavorite).toList(growable: false);
    final featuredEvents =
        overview.featuredEvents.map(_mapEvent).toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Seus Favoritos',
            onPressed: () {},
          ),
          FavoritesStrip(
            items: favorites,
            pinFirst: true,
          ),
          const SizedBox(height: 8),
          InvitesBannerBuilder(
            onPressed: _openInviteFlow,
            margin: EdgeInsets.only(bottom: 16),
          ),
          SectionHeader(
            title: 'Seus Eventos',
            onPressed: _openMyEvents,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.8 * 9 / 16,
            child: CarouselView(
              itemExtent: MediaQuery.of(context).size.width * 0.8,
              itemSnapping: true,
              children: featuredEvents
                  .map((event) => CarouselEventCard(data: event))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Proximos Eventos',
            onPressed: _openMyEvents,
          ),
          const SizedBox(height: 16),
          StreamValueBuilder<List<EventModel>>(
            streamValue: _upcomingController.upcomingEventsStreamValue,
            builder: (context, events) {
              if (events.isEmpty) {
                return _EmptyUpcomingEventsState(onExplore: _openMyEvents);
              }

              final cards = events
                  .map(_mapScheduleEvent)
                  .toList(growable: false);

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final event = cards[index];
                  return UpcomingEventCard(
                    data: event,
                    onTap: () => _openEventDetailSlug(event.slug),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  FavoriteItemData _mapFavorite(HomeFavorite favorite) {
    return FavoriteItemData(
      title: favorite.title,
      imageUrl: favorite.imageUri?.toString(),
      assetPath: favorite.assetPath,
      badgeIcon: favorite.badgeIcon,
      isPrimary: favorite.isPrimary,
    );
  }

  EventCardData _mapEvent(HomeEvent event) {
    final slug = event.slug;
    return EventCardData(
      slug: slug,
      title: event.title,
      imageUrl: event.imageUri.toString(),
      startDateTime: event.startDateTime,
      venue: event.location,
      participants: [
        if (event.artist.isNotEmpty)
          EventParticipantData(
            name: event.artist,
          ),
      ],
    );
  }

  EventCardData _mapScheduleEvent(EventModel event) {
    final imageUrl = event.thumb?.thumbUri.value.toString() ??
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';
    final participants = event.artists
        .map(
          (artist) => EventParticipantData(
            name: artist.name.value,
            isHighlight: artist.isHighlight.value,
          ),
        )
        .toList(growable: false);
    final startDate = event.dateTimeStart.value ?? DateTime.now();
    final slugSource = event.id.value;
    final slug = slugSource.isNotEmpty
        ? _slugify(slugSource)
        : _slugify(event.title.value);

    return EventCardData(
      slug: slug,
      title: event.title.value,
      imageUrl: imageUrl,
      startDateTime: startDate,
      venue: event.location.value,
      participants: participants,
    );
  }

  String _slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _openInviteFlow() {
    context.router.push(const InviteFlowRoute());
  }

  void _openMyEvents() {
    context.router.push(const ScheduleRoute());
  }

  void _openEventDetailSlug(String slug) {
    context.router.push(EventDetailRoute(slug: slug));
  }

}

class _EmptyUpcomingEventsState extends StatelessWidget {
  const _EmptyUpcomingEventsState({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sem próximos eventos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Confirme convites na agenda para vê-los por aqui.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Ir para agenda'),
            ),
          ],
        ),
      ),
    );
  }
}
