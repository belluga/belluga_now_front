import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class ThumbModel {
  final ThumbTypeValue thumbType;
  final ThumbUriValue thumbUri;

  ThumbModel({required this.thumbUri, required this.thumbType});

  factory ThumbModel.fromPrimitives({
    required String url,
    String? type,
  }) {
    final normalizedType =
        (type != null && type.isNotEmpty) ? type : ThumbTypes.image.name;
    return ThumbModel(
      thumbUri: ThumbUriValue(defaultValue: Uri.parse(url))..parse(url),
      thumbType:
          ThumbTypeValue(defaultValue: ThumbTypes.image)..parse(normalizedType),
    );
  }
}
