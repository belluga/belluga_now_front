import 'package:belluga_now/domain/courses/enums/thumb_types.dart';
import 'package:belluga_now/domain/courses/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/thumb_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart'
    as dal;

class ThumbModel {
  final ThumbTypeValue thumbType;
  final ThumbUriValue thumbUri;

  ThumbModel({required this.thumbUri, required this.thumbType});

  factory ThumbModel.fromDto(ThumbDto dto) {
    final thumbType = dto.type == 'image' ? ThumbTypes.image : ThumbTypes.image;
    return ThumbModel(
      thumbUri: ThumbUriValue(defaultValue: Uri.parse(dto.url))..parse(dto.url),
      thumbType: ThumbTypeValue(defaultValue: thumbType)..parse(dto.type),
    );
  }

  factory ThumbModel.fromDalDto(dal.ThumbDTO dto) {
    final uri = dto.data['url'] as String? ?? '';
    final thumbType =
        dto.type.isNotEmpty ? dto.type : ThumbTypes.image.name;
    return ThumbModel(
      thumbUri: ThumbUriValue(defaultValue: Uri.parse(uri))..parse(uri),
      thumbType:
          ThumbTypeValue(defaultValue: ThumbTypes.image)..parse(thumbType),
    );
  }
}
