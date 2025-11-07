import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';

abstract class FavoriteRepositoryContract {
  Future<List<Favorite>> fetchFavorites();
  Future<List<FavoriteResume>> fetchFavoriteResumes();
}
