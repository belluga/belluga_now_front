import 'package:belluga_now/domain/external_course/external_course_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/external_course_dto.dart';
import 'package:belluga_now/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:belluga_now/presentation/screens/dashboard/view_models/external_courses_summary.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class ExternalCoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final externalCoursesSteamValue = StreamValue<List<ExternalCourseModel>?>(
    defaultValue: null,
  );
  final summarySteamValue = StreamValue<ExternalCoursesSummary?>(
    defaultValue: null,
  );

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
    final List<ExternalCourseDTO> _dashboardSummary =
        await backend.getExternalCourses();

    final _externalCourses = _dashboardSummary
        .map(
          (externalCourseDto) => ExternalCourseModel.fromDTO(externalCourseDto),
        )
        .toList();

    externalCoursesSteamValue.addValue(_externalCourses);

    summarySteamValue.addValue(
      ExternalCoursesSummary(
        items: _externalCourses,
        total: _externalCourses.length,
      ),
    );
  }
}
