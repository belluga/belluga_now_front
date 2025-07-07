import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

@RoutePage()
class CourseScreen extends StatefulWidget {
  final MongoIDValue courseId;

  const CourseScreen({super.key, required this.courseId});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late CourseScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<CourseScreenController>(
      CourseScreenController(courseId: widget.courseId),
    );
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamValueBuilder<CourseModel>(
          streamValue: _controller.courseStreamValue,
          onNullWidget: SizedBox.shrink(),
          builder: (context, course) {
            return Text(course.title.value);
          },
        ),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Text(
          'Tela do Curso',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    GetIt.I.unregister<CourseScreenController>();
  }
}
