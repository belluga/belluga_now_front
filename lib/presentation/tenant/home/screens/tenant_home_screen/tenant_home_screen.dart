import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorites_strip.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
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
  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Seus Favoritos',
                onPressed: () {},
              ),
              _FavoritesSection(controller: _controller),
              const SizedBox(height: 8),
              InvitesBannerBuilder(
                onPressed: _openInviteFlow,
                margin: EdgeInsets.only(bottom: 16),
              ),
              SectionHeader(
                title: 'Seus Eventos',
                onPressed: _openMyEvents,
              ),
              _FeaturedEventsSection(controller: _controller),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'Proximos Eventos',
                onPressed: _openMyEvents,
              ),
              const SizedBox(height: 16),
              StreamValueBuilder<List<VenueEventResume>>(
                streamValue: _controller.upcomingEventsStreamValue,
                builder: (context, events) {
                  if (events.isEmpty) {
                    return _EmptyUpcomingEventsState(onExplore: _openMyEvents);
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return UpcomingEventCard(
                        event: event,
                        onTap: () => _openEventDetailSlug(event.slug),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.controller});

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
          return const _EmptyFavoritesState();
        }
        return FavoritesStrip(items: items, pinFirst: true);
      },
    );
  }
}

class _FeaturedEventsSection extends StatelessWidget {
  const _FeaturedEventsSection({required this.controller});

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return StreamValueBuilder<List<VenueEventResume>?>(
      streamValue: controller.featuredEventsStreamValue,
      onNullWidget: SizedBox(
        height: width * 0.8 * 9 / 16,
        child: const Center(child: CircularProgressIndicator()),
      ),
      builder: (context, events) {
        final items = events ?? const <VenueEventResume>[];
        if (items.isEmpty) {
          return const _EmptyFeaturedEventsState();
        }

        final cardWidth = width * 0.8;
        final cardHeight = cardWidth * 9 / 16;

        return SizedBox(
          height: cardHeight,
          child: CarouselView(
            itemExtent: cardWidth,
            itemSnapping: true,
            children:
                items.map((event) => CarouselEventCard(event: event)).toList(),
          ),
        );
      },
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

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

class _EmptyFeaturedEventsState extends StatelessWidget {
  const _EmptyFeaturedEventsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Nenhum evento em destaque.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
