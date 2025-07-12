import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:unifast_portal/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class MyCoursesDashboardController {
  final _myCoursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<CoursesSummary?> get myCoursesSummaryStreamValue {
    return _myCoursesRepository.myCoursesSummaryStreamValue;
  }

  StreamValue<List<CourseModel>?> get fastTracksItemsStreamValue {
    return _myCoursesRepository.fastTracksListStreamValue;
  }

  final navigationPreferenceStreamValue = StreamValue<bool>(
    defaultValue: false,
  );

  Future<void> init() async {
    _getMyCoursesSummary();
    _getFastTracksItems();
  }

  Future<void> _getMyCoursesSummary() async =>
      await _myCoursesRepository.getMyCoursesDashboardSummary();

  Future<void> _getFastTracksItems() async =>
      await _myCoursesRepository.getFastTracksList();
}
