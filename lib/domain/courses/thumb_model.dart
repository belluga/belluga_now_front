import 'package:flutter_laravel_backend_boilerplate/application/functions/enum_functions.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/enums/thumb_types.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/thumb_type_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/thumb_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

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
