import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/course_item_model.dart';
import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/course_item_summary_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/course_item_dto.dart';

import 'package:belluga_now/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:belluga_now/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class CoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final myCoursesSummaryStreamValue = StreamValue<CoursesSummary?>(
    defaultValue: null,
  );
  final fastTracksSummaryStreamValue = StreamValue<CoursesSummary?>(
    defaultValue: null,
  );
  final myCoursesListStreamValue = StreamValue<List<CourseBaseModel>?>(
    defaultValue: null,
  );
  final fastTracksListStreamValue = StreamValue<List<CourseBaseModel>?>(
    defaultValue: null,
  );
  final lastCreatedfastTracksStreamValue = StreamValue<List<CourseBaseModel>?>(
    defaultValue: null,
  );
  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  final fastTracksCategoriesListStreamValue =
      StreamValue<List<CourseCategoryModel>?>(defaultValue: null);

  Future<void> getMyCoursesDashboardSummary() async {
    if (myCoursesSummaryStreamValue.value != null) {
      return Future.value();
    }
    await _refreshMyCoursesDashboardSummary();
  }

  Future<void> _refreshMyCoursesDashboardSummary() async {
    final List<CourseItemSummaryDTO> _dashboardSummary = await backend
        .getMyCourses();

    final _courses = _dashboardSummary
        .map((courseDto) => CourseBaseModel.fromDto(courseDto))
        .toList();

    myCoursesListStreamValue.addValue(_courses);
    myCoursesSummaryStreamValue.addValue(
      CoursesSummary(items: _courses, total: _courses.length),
    );
  }

  Future<void> getFastTracksList() async {
    if (fastTracksListStreamValue.value != null) {
      return Future.value();
    }
    await _refreshFastTracksList();
  }

  Future<void> _refreshFastTracksList() async {
    final List<CourseItemSummaryDTO> _dashboardSummary = await backend
        .getLastFastTrackCourses();

    final _courses = _dashboardSummary
        .map((courseDto) => CourseBaseModel.fromDto(courseDto))
        .toList();

    fastTracksListStreamValue.addValue(_courses);
  }

  Future<void> getFastTracksLastCreatedList() async {
    if (lastCreatedfastTracksStreamValue.value != null) {
      return Future.value();
    }
    await _refreshFastTracksLastCreatedList();
  }

  Future<void> _refreshFastTracksLastCreatedList() async {
    final List<CourseItemSummaryDTO> _coursesDtos = await backend
        .getLastFastTrackCourses();

    _coursesDtos.sublist(0, 4);

    final _courses = _coursesDtos
        .map((courseDto) => CourseBaseModel.fromDto(courseDto))
        .toList();

    lastCreatedfastTracksStreamValue.addValue(_courses);
  }

  Future<CourseItemModel> courseItemGetDetails(String courseId) async {
    final CourseItemDetailsDTO _courseDTO = await backend.courseItemGetDetails(
      courseId,
    );
    return Future.value(CourseItemModel.fromDto(_courseDTO));
  }

  Future<List<CourseCategoryModel>> getFastTracksCategories() async {
    if (fastTracksCategoriesListStreamValue.value != null) {
      return Future.value(fastTracksCategoriesListStreamValue.value);
    }
    final List<CategoryDTO> _categoriesDTO = await backend
        .getFastTracksCategories();

    final _categoriesModel = _categoriesDTO
        .map((category) => CourseCategoryModel.fromDto(category))
        .toList();

    fastTracksCategoriesListStreamValue.addValue(_categoriesModel);
    return Future.value(_categoriesModel);
  }
}
