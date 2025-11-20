import 'package:belluga_now/domain/courses/enums/thumb_types.dart';
import 'package:belluga_now/domain/courses/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/courses/dtos/thumb_dto.dart';

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
}
