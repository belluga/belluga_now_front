import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_overview_dto.dart';

class HomeOverview {
  HomeOverview({
    required this.favorites,
    required this.featuredEvents,
    required this.upcomingEvents,
  });

  final List<HomeFavorite> favorites;
  final List<HomeEvent> featuredEvents;
  final List<HomeEvent> upcomingEvents;

  factory HomeOverview.fromDTO(HomeOverviewDTO dto) {
    return HomeOverview(
      favorites: dto.favorites
          .map((favoriteDTO) => HomeFavorite.fromDTO(favoriteDTO))
          .toList(),
      featuredEvents: dto.featuredEvents
          .map((eventDTO) => HomeEvent.fromDTO(eventDTO))
          .toList(),
      upcomingEvents: dto.upcomingEvents
          .map((eventDTO) => HomeEvent.fromDTO(eventDTO))
          .toList(),
    );
  }
}
