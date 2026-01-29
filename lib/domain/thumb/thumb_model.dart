import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart' as dal;

class ThumbModel {
  final ThumbTypeValue thumbType;
  final ThumbUriValue thumbUri;

  ThumbModel({required this.thumbUri, required this.thumbType});

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
