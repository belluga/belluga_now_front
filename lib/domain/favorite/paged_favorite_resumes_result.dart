import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class PagedFavoriteResumesResult {
  PagedFavoriteResumesResult({
    required this.items,
    required this.hasMoreValue,
    this.pinned,
  });

  final List<FavoriteResume> items;
  final DomainBooleanValue hasMoreValue;
  final FavoriteResume? pinned;

  bool get hasMore => hasMoreValue.value;
}
