import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_expert_avatar_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_expert_name_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/expert_dto.dart';

class MyCourseDashboardExpert {
  final MyCourseExpertNameValue name;
  final MyCourseExpertAvatarUriValue avatarUrl;

  MyCourseDashboardExpert({required this.name, required this.avatarUrl});

  factory MyCourseDashboardExpert.fromDTO(MyCourseDashboardExpertDTO expert) {
    final _avatarUrl = MyCourseExpertAvatarUriValue(
      defaultValue: Uri.parse(
        "https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308",
      ),
    )..tryParse(expert.avatarUrl);

    final _nameValue = MyCourseExpertNameValue()..tryParse(expert.name);

    return MyCourseDashboardExpert(name: _nameValue, avatarUrl: _avatarUrl);
  }
}
