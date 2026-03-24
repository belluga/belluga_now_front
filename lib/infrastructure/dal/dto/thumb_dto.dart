import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class ThumbDTO {
  String type;
  Map<String, dynamic> data;

  ThumbDTO({required this.type, required this.data});

  factory ThumbDTO.fromJson(Map<String, dynamic> json) {
    return ThumbDTO(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  ThumbModel toDomain() {
    final url = data['url'] as String? ?? '';
    final normalizedType = type.isNotEmpty ? type : ThumbTypes.image.name;
    return ThumbModel(
      thumbUri: ThumbUriValue(defaultValue: Uri.parse(url))..parse(url),
      thumbType:
          ThumbTypeValue(defaultValue: ThumbTypes.image)..parse(normalizedType),
    );
  }
}
