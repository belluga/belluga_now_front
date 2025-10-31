import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/presentation/tenant/screens/home/controller/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorites_strip.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:belluga_now/presentation/tenant/widgets/invites_banner.dart';
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
        title: SizedBox(
          height: 32,
          child: Image.asset(
            'assets/images/logo_horizontal.png',
            fit: BoxFit.contain,
          ),
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
            tooltip: 'Notificacoes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: const FloatingActionButtonCustom(),
      bottomNavigationBar: const BellugaBottomNavigationBar(),
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
    final upcomingEvents =
        overview.upcomingEvents.map(_mapEvent).toList(growable: false);

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
          InvitesBanner(onPressed: () {}),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Seus Eventos',
            onPressed: () {},
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
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingEvents.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final event = upcomingEvents[index];
              return UpcomingEventCard(data: event);
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
    return EventCardData(
      title: event.title,
      imageUrl: event.imageUri.toString(),
      startDateTime: event.startDateTime,
      location: event.location,
      artist: event.artist,
    );
  }
}
