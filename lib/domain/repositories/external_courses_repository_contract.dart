import 'package:flutter_laravel_backend_boilerplate/domain/external_course/external_courses_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class ExternalCoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

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
    final ExternalCoursesSummaryDTO _dashboardSummary = await backend
        .externalCoursesGetDashboardSummary();
    summarySteamValue.addValue(
      ExternalCoursesSummary.fromDTO(_dashboardSummary),
    );
  }
}
