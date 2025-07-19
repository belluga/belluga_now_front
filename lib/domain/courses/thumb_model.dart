import 'package:unifast_portal/application/functions/enum_functions.dart';
import 'package:unifast_portal/domain/courses/enums/thumb_types.dart';
import 'package:unifast_portal/domain/courses/value_objects/thumb_type_value.dart';
import 'package:unifast_portal/domain/value_objects/thumb_uri_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/thumb_dto.dart';

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
