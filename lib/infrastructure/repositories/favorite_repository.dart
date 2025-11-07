import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/infrastructure/mappers/home_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';
import 'package:get_it/get_it.dart';

class FavoriteRepository extends FavoriteRepositoryContract with HomeDtoMapper {
  // TODO(belluga): When Favorite aggregate lands, map DTOs directly into the
  // domain entity and expose additional projections (resumes, stats) from
  // that type instead of returning resumes here.
  @override
  Future<List<FavoriteResume>> fetchFavorites() async {
    final List<HomeFavoriteDTO> dtos = await backend.home.fetchFavorites();
    return dtos.map(mapFavoriteResume).toList(growable: false);
  }

  BackendContract get backend => GetIt.I.get<BackendContract>();
}
