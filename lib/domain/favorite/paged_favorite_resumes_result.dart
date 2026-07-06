import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class PagedFavoriteResumesResult {
  PagedFavoriteResumesResult({
    required this.items,
    required this.hasMoreValue,
  });

  final List<FavoriteResume> items;
  final DomainBooleanValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}

PagedFavoriteResumesResult pagedFavoriteResumesResultFromRaw({
  required List<FavoriteResume> items,
  required Object? hasMore,
}) {
  return PagedFavoriteResumesResult(
    items: items,
    hasMoreValue:
        (DomainBooleanValue(defaultValue: false, isRequired: false)
          ..parse(hasMore?.toString())),
  );
}
