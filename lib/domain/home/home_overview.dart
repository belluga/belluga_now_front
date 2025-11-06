import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';

class HomeOverview {
  HomeOverview({
    required this.favorites,
    required this.featuredEvents,
    required this.upcomingEvents,
  });

  final List<HomeFavorite> favorites;
  final List<HomeEvent> featuredEvents;
  final List<HomeEvent> upcomingEvents;

}
