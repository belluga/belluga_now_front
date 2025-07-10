import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';

import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:unifast_portal/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class CoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final summarySteamValue = StreamValue<CoursesSummary?>(defaultValue: null);
  final coursesSteamValue = StreamValue<List<CourseModel>?>(defaultValue: null);
  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  Future<void> init() async {
    await getDashboardSummary();
  }

  Future<void> getDashboardSummary() async {
    if (summarySteamValue.value != null) {
      return Future.value();
    }
    await _refreshDashboardSummary();
  }

  Future<void> _refreshDashboardSummary() async {
    final List<CourseDTO> _dashboardSummary = await backend.getMyCourses();

    final _courses = _dashboardSummary
        .map((courseDto) => CourseModel.fromDto(courseDto))
        .toList();

    coursesSteamValue.addValue(_courses);
    summarySteamValue.addValue(
      CoursesSummary(items: _courses, total: _courses.length),
    );
  }

  Future<CourseItemModel> courseItemGetDetails(String courseId) async {
    final CourseItemDTO _courseDTO = await backend.courseItemGetDetails(courseId);
    return Future.value(CourseItemModel.fromDto(_courseDTO));
  }
}
