import 'package:belluga_now/application/functions/enum_functions.dart';
import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/course_childrens_summary.dart';
import 'package:belluga_now/domain/courses/course_content_model.dart';
import 'package:belluga_now/domain/courses/course_item_model.dart';
import 'package:belluga_now/domain/courses/enums/thumb_types.dart';
import 'package:belluga_now/domain/courses/file_model.dart';
import 'package:belluga_now/domain/courses/teacher_model.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/courses/value_objects/category_name.dart';
import 'package:belluga_now/domain/courses/value_objects/items_total_value.dart';
import 'package:belluga_now/domain/courses/value_objects/expert_name_value.dart';
import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';
import 'package:belluga_now/domain/courses/value_objects/teacher_is_highlight.dart';
import 'package:belluga_now/domain/courses/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/external_course/external_course_model.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_description_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_initial_password_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_platform_uri_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_title_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/courses/video_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/category_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/course_childrens_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/course_content_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/course_item_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/course_item_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/files_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/teacher_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/course/video_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/external_course_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';
import 'package:flutter/material.dart';

mixin CourseDtoMapper {
  ThumbModel mapThumb(ThumbDTO dto) {
    return ThumbModel(
      thumbType: ThumbTypeValue(
        defaultValue: EnumFunctions.enumFromString(
          values: ThumbTypes.values,
          enumItem: dto.type,
          defaultValue: ThumbTypes.image,
        ),
      ),
      thumbUri: ThumbUriValue(
        defaultValue: Uri.parse(dto.data['url'] as String),
      ),
    );
  }

  TeacherModel mapTeacher(TeacherDTO dto) {
    final avatar = URIValue(
      defaultValue: Uri.parse(
        'https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308',
      ),
    )..tryParse(dto.avatarUrl);

    return TeacherModel(
      name: ExpertNameValue()..tryParse(dto.name),
      avatarUrl: avatar,
      isHightlight: TeacherIsHighlight(defaultValue: false)
        ..set(dto.highlight ?? false),
    );
  }

  FileModel mapFile(FileDTO dto) {
    return FileModel(
      url: URIValue()..parse(dto.url),
      title: TitleValue()..parse(dto.title),
      description: DescriptionValue()..tryParse(dto.description),
      thumb: mapThumb(dto.thumb),
    );
  }

  CourseCategoryModel mapCourseCategory(CategoryDTO dto) {
    return CourseCategoryModel(
      id: MongoIDValue()..parse(dto.id),
      name: CategoryNameValue()..parse(dto.name),
      slug: SlugValue()..parse(dto.slug),
      color: ColorValue(defaultValue: Colors.tealAccent)
        ..tryParse(dto.colorHex),
    );
  }

  CourseBaseModel mapCourseSummary(CourseItemSummaryDTO dto) {
    return CourseBaseModel(
      id: MongoIDValue()..parse(dto.id),
      title: TitleValue()..parse(dto.title),
      description: DescriptionValue()..parse(dto.description),
      thumb: mapThumb(dto.thumb),
      categories: dto.categories?.map(mapCourseCategory).toList(),
      teachers: dto.teachers.map(mapTeacher).toList(),
    );
  }

  CourseChildrensSummary mapCourseChildrensSummary(
    CourseChildrensSummaryDTO dto,
  ) {
    return CourseChildrensSummary(
      total: ItemsTotalValue()..parse(dto.total.toString()),
      label: TitleValue()..parse(dto.label),
    );
  }

  VideoModel mapVideo(VideoDTO dto) {
    return VideoModel(
      url: URIValue()..parse(dto.url),
      thumb: mapThumb(dto.thumb),
    );
  }

  CourseContentModel mapCourseContent(CourseContentDTO dto) {
    final videoDto = dto.video;
    final htmlDto = dto.htmlContent;

    return CourseContentModel(
      video: videoDto != null ? mapVideo(videoDto) : null,
      html:
          htmlDto != null ? (GenericStringValue()..parse(htmlDto)) : null,
    );
  }

  CourseItemModel mapCourseItem(CourseItemDetailsDTO dto) {
    return CourseItemModel(
      id: MongoIDValue()..parse(dto.id),
      title: TitleValue()..parse(dto.title),
      description: DescriptionValue()..parse(dto.description),
      thumb: mapThumb(dto.thumb),
      teachers: dto.teachers.map(mapTeacher).toList(),
      categories: dto.categories?.map(mapCourseCategory).toList(),
      childrensSummary: dto.childrensSummary != null
          ? mapCourseChildrensSummary(dto.childrensSummary!)
          : null,
      childrens: dto.childrens.map(mapCourseSummary).toList(),
      files: dto.files.map(mapFile).toList(),
      content: dto.content != null ? mapCourseContent(dto.content!) : null,
      next: dto.next != null ? mapCourseSummary(dto.next!) : null,
      parent: dto.parent != null ? mapCourseSummary(dto.parent!) : null,
    );
  }

  ExternalCourseModel mapExternalCourse(ExternalCourseDTO dto) {
    return ExternalCourseModel(
      thumb: mapThumb(dto.thumb),
      title: ExternalCourseTitleValue()..tryParse(dto.title),
      description: ExternalCourseDescriptionValue()
        ..tryParse(dto.description),
      platformUrl: ExternalCoursePlatformUriValue(
        defaultValue: Uri.parse(
          'https://media.istockphoto.com/id/1128826884/pt/vetorial/no-image-vector-symbol-missing-available-icon-no-gallery-for-this-moment.jpg?s=1024x1024&w=is&k=20&c=9vW4OtrgvQA6hfnIvdk-tQK0CPvlKyWTPh10p064u9k=',
        ),
      )..tryParse(dto.platformUrl),
      initialPassword: ExternalCourseInitialPasswordValue()
        ..tryParse(dto.initialPassword),
    );
  }
}
