import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:get_it/get_it.dart';

class FavoriteRepository extends FavoriteRepositoryContract {
  @override
  Future<List<Favorite>> fetchFavorites() async {
    final List<FavoritePreviewDTO> dtos =
        await backend.favorites.fetchFavorites();
    return dtos.map((dto) => dto.toDomain()).toList(growable: false);
  }

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    final favorites = await fetchFavorites();
    return favorites
        .map(FavoriteResume.fromFavorite)
        .toList(growable: false);
  }

  BackendContract get backend => GetIt.I.get<BackendContract>();
}
