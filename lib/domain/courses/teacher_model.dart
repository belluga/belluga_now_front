import 'package:belluga_now/domain/courses/value_objects/expert_name_value.dart';
import 'package:belluga_now/domain/courses/value_objects/teacher_is_highlight.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class TeacherModel {
  final ExpertNameValue name;
  final URIValue avatarUrl;
  final TeacherIsHighlight isHightlight;

  TeacherModel({
    required this.name,
    required this.avatarUrl,
    required this.isHightlight,
  });

  factory TeacherModel.fromDTO(TeacherDTO expert) {
    final _avatarUrl = URIValue(
      defaultValue: Uri.parse(
        "https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308",
      ),
    )..tryParse(expert.avatarUrl);

    final _nameValue = ExpertNameValue()..tryParse(expert.name);
    final _isHightLight = TeacherIsHighlight(defaultValue: false)
      ..set(expert.highlight ?? false);

    return TeacherModel(
      name: _nameValue,
      avatarUrl: _avatarUrl,
      isHightlight: _isHightLight,
    );
  }
}
