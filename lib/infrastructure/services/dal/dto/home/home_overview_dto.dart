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
}
