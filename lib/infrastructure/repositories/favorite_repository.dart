import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/paged_favorite_resumes_result.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:get_it/get_it.dart';

import 'favorite_repository_paging_mixin.dart';

class FavoriteRepository extends FavoriteRepositoryContract
    with FavoriteRepositoryPagingMixin {
  @override
  Future<List<Favorite>> fetchFavorites() async {
    final List<FavoritePreviewDTO> dtos = await backend.favorites
        .fetchFavorites();
    return dtos.map((dto) => dto.toDomain()).toList(growable: false);
  }

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    final dtos = await backend.favorites.fetchFavorites();
    return dtos.map((dto) => dto.toResume()).toList(growable: false);
  }

  @override
  Future<PagedFavoriteResumesResult> fetchFavoriteResumesPage({
    required int page,
    required int pageSize,
  }) async {
    final pageDto = await backend.favorites.fetchFavoritesPage(
      page: page,
      pageSize: pageSize,
    );

    return PagedFavoriteResumesResult(
      items: pageDto.items.map((dto) => dto.toResume()).toList(growable: false),
      hasMoreValue:
          (DomainBooleanValue(defaultValue: false, isRequired: false)
            ..parse(pageDto.hasMore.toString())),
    );
  }

  BackendContract get backend => GetIt.I.get<BackendContract>();
}
