import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/my_courses_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/my_courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class MyCoursesDashboardController {
  
  final _myCoursesRepository = GetIt.I
      .get<MyCoursesRepositoryContract>();

  StreamValue<MyCoursesSummary?> get myCoursesSummaryStreamValue {
    return _myCoursesRepository.summarySteamValue;
  }

  final navigationPreferenceStreamValue = StreamValue<bool>(defaultValue: false);

  Future<void> init() async {
    await _getMyCoursesSummary();
  }

  Future<void> _getMyCoursesSummary() async =>
      await _myCoursesRepository.getDashboardSummary();


}
