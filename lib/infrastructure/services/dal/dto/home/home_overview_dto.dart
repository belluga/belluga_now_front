import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';

class HomeOverviewDTO {
  const HomeOverviewDTO({
    required this.favorites,
    required this.featuredEvents,
    required this.upcomingEvents,
  });

  final List<HomeFavoriteDTO> favorites;
  final List<HomeEventDTO> featuredEvents;
  final List<HomeEventDTO> upcomingEvents;

  HomeOverview toDomain() {
    return HomeOverview(
      favorites: favorites.map((dto) => dto.toDomain()).toList(),
      featuredEvents: featuredEvents.map((dto) => dto.toDomain()).toList(),
      upcomingEvents: upcomingEvents.map((dto) => dto.toDomain()).toList(),
    );
  }
}
