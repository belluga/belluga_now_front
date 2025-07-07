import 'dart:async';

import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseScreenController implements Disposable{

  CourseScreenController({required this.courseId});

  final MongoIDValue courseId;

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<CourseModel?> get courseStreamValue => _coursesRepository.currentCourseStreamValue;
  
  Future<void> init() async {
    await _getCourse();
  }

  Future<void> _getCourse() async {
    await _coursesRepository.getCourseDetails(courseId.value);
  }



  @override
  FutureOr onDispose() {
    //
  }
}
