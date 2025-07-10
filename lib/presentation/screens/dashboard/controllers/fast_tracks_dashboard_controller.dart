import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:unifast_portal/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FastTracksDashboardController {
  final _myCoursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<CoursesSummary?> get myCoursesSummaryStreamValue {
    return _myCoursesRepository.fastTracksSummarySteamValue;
  }

  final navigationPreferenceStreamValue = StreamValue<bool>(
    defaultValue: false,
  );

  Future<void> init() async {
    await _getSummary();
  }

  Future<void> _getSummary() async =>
      await _myCoursesRepository.getFastTracksDashboardSummary();
}
