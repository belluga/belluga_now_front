import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class FileModel {
  final URIValue url;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;

  FileModel({
    required this.url,
    required this.title,
    required this.description,
    required this.thumb,
  });
}
