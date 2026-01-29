import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';

abstract class FavoriteBackendContract {
  Future<List<FavoritePreviewDTO>> fetchFavorites();
}
