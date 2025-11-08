import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';

mixin MapDtoMapper {
  CityPoiModel mapCityPoi(CityPoiDTO dto) {
    final idValue = CityPoiIdValue()..parse(dto.id);
    final nameValue = CityPoiNameValue()..parse(dto.name);
    final descriptionValue = DescriptionValue()..parse(dto.description);
    final addressValue = CityPoiAddressValue()..parse(dto.address);
    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(dto.latitude.toString()),
      longitudeValue: LongitudeValue()..parse(dto.longitude.toString()),
    );
    final priorityValue = PoiPriorityValue()..parse(dto.priority.toString());
    AssetPathValue? assetPathValue;
    if (dto.assetPath != null && dto.assetPath!.isNotEmpty) {
      assetPathValue = AssetPathValue(
        defaultValue: dto.assetPath!,
        isRequired: true,
      )..parse(dto.assetPath);
    }
    DistanceInMetersValue? movementRadiusValue;
    if (dto.movementRadiusMeters != null) {
      movementRadiusValue = DistanceInMetersValue()
        ..parse(dto.movementRadiusMeters!.toString());
    }
    final tagValues = dto.tags
        .map((tag) => PoiTagValue()..parse(tag))
        .toList(growable: false);

    return CityPoiModel(
      idValue: idValue,
      nameValue: nameValue,
      descriptionValue: descriptionValue,
      addressValue: addressValue,
      category: dto.category,
      coordinate: coordinate,
      priorityValue: priorityValue,
      assetPathValue: assetPathValue,
      isDynamic: dto.isDynamic,
      movementRadiusValue: movementRadiusValue,
      tagValues: tagValues,
    );
  }
}
