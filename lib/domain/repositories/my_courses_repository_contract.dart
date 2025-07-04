import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/my_courses_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class MyCoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final summarySteamValue = StreamValue<MyCoursesSummary?>(defaultValue: null);

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
    summarySteamValue.addValue(MyCoursesSummary.fromDTO(_dashboardSummary));
  }
}
