import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';

abstract class HomeBackendContract {
  Future<List<HomeFavoriteDTO>> fetchFavorites();
  Future<List<HomeEventDTO>> fetchFeaturedEvents();
  Future<List<HomeEventDTO>> fetchUpcomingEvents();
}
