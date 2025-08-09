import 'dart:async';

import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CoursesListScreenController implements Disposable {
  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<List<CourseBaseModel>?> get courseStreamValue =>
      _coursesRepository.myCoursesListStreamValue;

  @override
  FutureOr onDispose() {
    //
  }
}
