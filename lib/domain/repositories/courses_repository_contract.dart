import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/courses_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class CoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final summarySteamValue = StreamValue<CoursesSummary?>(defaultValue: null);
  final currentCourseStreamValue = StreamValue<CourseModel?>();

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
    final MyCoursesSummaryDTO _dashboardSummary = await backend
        .myCoursesGetDashboardSummary();
    summarySteamValue.addValue(CoursesSummary.fromDTO(_dashboardSummary));
  }

  Future<void> getCourseDetails(String courseId) async {
    final CourseDTO _courseDTO = await backend.courseGetDetails(courseId);
    currentCourseStreamValue.addValue(CourseModel.fromDto(_courseDTO));

  }
}
