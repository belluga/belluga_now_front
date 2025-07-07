import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_type_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/expert_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/thumb_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseDashboardModel {
  final MongoIDValue id;
  final TitleValue title;
  final CourseTypeModel type;
  final DescriptionValue description;
  final ThumbUriValue thumbUrl;
  final ExpertModel expert;

  CourseDashboardModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumbUrl,
    required this.expert,
  });

  factory CourseDashboardModel.fromDTO(MyCourseDashboardDTO myCourse) {
    final _idValue = MongoIDValue()..parse(myCourse.id);
    final _titleValue = TitleValue()..tryParse(myCourse.title);
    final _typeValue = CourseTypeModel.fromDto(myCourse.type);
    final _description = DescriptionValue()
      ..tryParse(myCourse.description);
    final _thumbUrl = ThumbUriValue(
      defaultValue: Uri.parse(
        "https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308",
      ),
    )..tryParse(myCourse.thumbUrl);

    final _expert = ExpertModel.fromDTO(myCourse.expert);

    return CourseDashboardModel(
      id: _idValue,
      title: _titleValue,
      expert: _expert,
      type: _typeValue,
      thumbUrl: _thumbUrl,
      description: _description,
    );
  }
}
