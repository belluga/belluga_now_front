import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseScreenController implements Disposable{

  CourseScreenController({required this.courseId});

  final MongoIDValue courseId;

  final _coursesRepository = GetIt.I.get<CoursesRepository>();

  final courseStreamValue = StreamValue<CourseModel?>();
  
  Future<void> init() async {
    await _getCourse();
  }

  Future<void> _getCourse() async {
    // Simulate fetching course data
    await Future.delayed(Duration(seconds: 1));
    
    // Example course data
    final fetchedCourse = CourseModel(
      id: courseId,
      title: 'Sample Course',
      description: 'This is a sample course description.',
    );
    
    courseStreamValue.addValue(fetchedCourse);
  }



  @override
  FutureOr onDispose() {
    //
  }
}
