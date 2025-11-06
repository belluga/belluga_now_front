import 'package:belluga_now/domain/courses/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class ThumbModel {
  final ThumbTypeValue thumbType;
  final ThumbUriValue thumbUri;

  ThumbModel({required this.thumbUri, required this.thumbType});
}
