import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class EventTypeModel {
  final MongoIDValue id;
  final TitleValue name;
  final SlugValue slug;
  final DescriptionValue description;
  final SlugValue icon;
  final ColorValue color;
  EventTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.color,
  });
}
