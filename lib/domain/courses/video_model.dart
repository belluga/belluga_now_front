import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class VideoModel {
  final URIValue url;
  final ThumbModel thumb;

  VideoModel({required this.url, required this.thumb});
}
