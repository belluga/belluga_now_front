import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/domain/repositories/home_repository_contract.dart';
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

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  late final Future<HomeOverview> _overviewFuture;

  @override
  void initState() {
    super.initState();
    final repository = GetIt.I<HomeRepositoryContract>();
    _overviewFuture = repository.fetchOverview();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeOverview>(
      future: _overviewFuture,
      builder: (context, snapshot) {
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
          floatingActionButton: FloatingActionButtonCustom(),
          bottomNavigationBar: BellugaBottomNavigationBar(),
          body: SafeArea(
            child: _buildBody(context, snapshot),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<HomeOverview> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Center(
        child: Text(
          'Nao foi possivel carregar os dados.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final overview = snapshot.requireData;
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
      imageUrl: favorite.imageUrl,
      assetPath: favorite.assetPath,
      badgeIcon: favorite.badgeIcon,
      isPrimary: favorite.isPrimary,
    );
  }

  EventCardData _mapEvent(HomeEvent event) {
    return EventCardData(
      title: event.title,
      imageUrl: event.imageUrl,
      startDateTime: event.startDateTime,
      location: event.location,
      artist: event.artist,
    );
  }
}
