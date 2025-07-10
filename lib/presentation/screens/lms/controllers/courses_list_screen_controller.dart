import 'dart:async';

import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CoursesListScreenController implements Disposable {
  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<List<CourseModel>?> get courseStreamValue =>
      _coursesRepository.myCoursesListSteamValue;

  @override
  FutureOr onDispose() {
    //
  }
}
