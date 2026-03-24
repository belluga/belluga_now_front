import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class FavoriteRepositoryContract {
  final favoriteResumesStreamValue =
      StreamValue<List<FavoriteResume>?>(defaultValue: null);

  Future<List<Favorite>> fetchFavorites();
  Future<List<FavoriteResume>> fetchFavoriteResumes();

  Future<void> initializeFavoriteResumes() async {
    if (favoriteResumesStreamValue.value != null) {
      return;
    }
    await refreshFavoriteResumes();
  }

  Future<void> refreshFavoriteResumes() async {
    final previousValue = favoriteResumesStreamValue.value;
    try {
      final favoriteResumes = await fetchFavoriteResumes();
      favoriteResumesStreamValue.addValue(favoriteResumes);
    } catch (_) {
      favoriteResumesStreamValue.addValue(previousValue);
    }
  }
}
