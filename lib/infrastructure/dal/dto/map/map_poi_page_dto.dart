import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';

class MapPoiPageDTO {
  MapPoiPageDTO({
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required List<CityPoiDTO> items,
  }) : items = List<CityPoiDTO>.unmodifiable(items);

  final int page;
  final int pageSize;
  final bool hasMore;
  final List<CityPoiDTO> items;
}
