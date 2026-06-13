import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class FavoriteRepositoryContract {
  static const int _favoriteResumesFetchMaxAttempts = 3;
  static const Duration _favoriteResumesRetryDelay = Duration(
    milliseconds: 250,
  );

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
    for (var attempt = 1;
        attempt <= _favoriteResumesFetchMaxAttempts;
        attempt++) {
      try {
        final favoriteResumes = await fetchFavoriteResumes();
        favoriteResumesStreamValue.addValue(favoriteResumes);
        return;
      } catch (error) {
        final hasMoreAttempts = attempt < _favoriteResumesFetchMaxAttempts;
        if (hasMoreAttempts) {
          await Future<void>.delayed(_favoriteResumesRetryDelay);
        }
      }
    }

    if (previousValue != null) {
      favoriteResumesStreamValue.addValue(previousValue);
      return;
    }

    favoriteResumesStreamValue.addValue(const <FavoriteResume>[]);
  }
}
