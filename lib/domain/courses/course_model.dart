import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_category_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_items_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_type_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/discipline_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/expert_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseModel {
  final MongoIDValue id;
  final TitleValue title;
  final CourseTypeModel type;
  final DescriptionValue description;
  final ThumbModel thumb;
  final List<CourseCategoryModel> categories;
  final ExpertModel? expert;
  final CourseItemsSummary disciplinesSummary;
  final List<DisciplineModel> disciplines;

  CourseModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumb,
    required this.categories,
    required this.expert,
    required this.disciplinesSummary,
    required this.disciplines,
  });

  factory CourseModel.fromDto(CourseDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = TitleValue()..parse(dto.title);
    final _type = CourseTypeModel.fromDto(dto.type);
    final _description = DescriptionValue()..parse(dto.description);
    final _thumb = ThumbModel.fromDTO(dto.thumb);
    final _categories = dto.categories
        .map((item) => CourseCategoryModel.fromDto(item))
        .toList();

    final _expert = ExpertModel.fromDTO(dto.expert);
    final _disciplinesSummary = CourseItemsSummary.fromDTO(
      dto.disciplinesSummary,
    );

    final _disciplines = dto.disciplines
        .map((item) => DisciplineModel.fromDTO((item)))
        .toList();

    return CourseModel(
      id: _id,
      title: _title,
      type: _type,
      description: _description,
      thumb: _thumb,
      categories: _categories,
      expert: _expert,
      disciplinesSummary: _disciplinesSummary,
      disciplines: _disciplines,
    );
  }
}
