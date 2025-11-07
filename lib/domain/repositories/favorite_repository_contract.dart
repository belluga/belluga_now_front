import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';

abstract class FavoriteRepositoryContract {
  // TODO(belluga): Promote this to return List<Favorite> once the full
  // aggregate is defined (see domain/favorite/favorite.dart). Keep the
  // resume-specific version for legacy screens until migration is complete.
  Future<List<FavoriteResume>> fetchFavorites();
}
