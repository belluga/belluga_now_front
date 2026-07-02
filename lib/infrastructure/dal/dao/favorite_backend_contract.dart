import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_page_dto.dart';

abstract class FavoriteBackendContract {
  Future<List<FavoritePreviewDTO>> fetchFavorites();

  Future<FavoritePreviewPageDTO> fetchFavoritesPage({
    required int page,
    required int pageSize,
  }) async {
    final resolvedPage = page < 1 ? 1 : page;
    final resolvedPageSize = pageSize < 1 ? 10 : pageSize;
    final favorites = await fetchFavorites();
    final startIndex = (resolvedPage - 1) * resolvedPageSize;
    final items = favorites
        .skip(startIndex)
        .take(resolvedPageSize)
        .toList(growable: false);

    return FavoritePreviewPageDTO(
      items: items,
      hasMore: (startIndex + resolvedPageSize) < favorites.length,
    );
  }

  Future<void> favoriteAccountProfile(String accountProfileId);

  Future<void> unfavoriteAccountProfile(String accountProfileId);
}
