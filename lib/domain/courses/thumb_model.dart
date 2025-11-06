import 'package:belluga_now/application/functions/enum_functions.dart';
import 'package:belluga_now/domain/courses/enums/thumb_types.dart';
import 'package:belluga_now/domain/courses/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class ThumbModel {
  ThumbTypeValue thumbType;
  ThumbUriValue thumbUri;

  ThumbModel({required this.thumbUri, required this.thumbType});

  factory ThumbModel.fromDTO(ThumbDTO dto) {
    return ThumbModel(
      thumbType: ThumbTypeValue(
        defaultValue: EnumFunctions.enumFromString(
          values: ThumbTypes.values,
          enumItem: dto.type,
          defaultValue: ThumbTypes.image,
        ),
      ),
      thumbUri: ThumbUriValue(
        defaultValue: Uri.parse(dto.data['url'] as String),
      ),
    );
  }
}
