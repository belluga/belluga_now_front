import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';

class PagedFavoriteResumesResult {
  const PagedFavoriteResumesResult({
    required this.items,
    required this.hasMore,
  });

  final List<FavoriteResume> items;
  final bool hasMore;
}
