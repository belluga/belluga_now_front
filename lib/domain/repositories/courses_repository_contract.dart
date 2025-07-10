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

  final myCoursesSummarySteamValue = StreamValue<CoursesSummary?>(defaultValue: null);
  final fastTracksSummarySteamValue = StreamValue<CoursesSummary?>(defaultValue: null);
  final myCoursesListSteamValue = StreamValue<List<CourseModel>?>(defaultValue: null);
  final fastTracksListSteamValue = StreamValue<List<CourseModel>?>(defaultValue: null);
  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  Future<void> getMyCoursesDashboardSummary() async {
    if (myCoursesSummarySteamValue.value != null) {
      return Future.value();
    }
    await _refreshMyCoursesDashboardSummary();
  }

  Future<void> _refreshMyCoursesDashboardSummary() async {
    final List<CourseDTO> _dashboardSummary = await backend.getMyCourses();

    final _courses = _dashboardSummary
        .map((courseDto) => CourseModel.fromDto(courseDto))
        .toList();

    myCoursesListSteamValue.addValue(_courses);
    myCoursesSummarySteamValue.addValue(
      CoursesSummary(items: _courses, total: _courses.length),
    );
  }

  Future<void> getFastTracksDashboardSummary() async {
    if (fastTracksSummarySteamValue.value != null) {
      return Future.value();
    }
    await _refreshFastTracksDashboardSummary();
  }

  Future<void> _refreshFastTracksDashboardSummary() async {
    final List<CourseDTO> _dashboardSummary = await backend.getUnifastTracks();

    final _courses = _dashboardSummary
        .map((courseDto) => CourseModel.fromDto(courseDto))
        .toList();

    fastTracksListSteamValue.addValue(_courses);
    fastTracksSummarySteamValue.addValue(
      CoursesSummary(items: _courses, total: _courses.length),
    );
  }

  Future<CourseItemModel> courseItemGetDetails(String courseId) async {
    final CourseItemDTO _courseDTO = await backend.courseItemGetDetails(courseId);
    return Future.value(CourseItemModel.fromDto(_courseDTO));
  }
}
