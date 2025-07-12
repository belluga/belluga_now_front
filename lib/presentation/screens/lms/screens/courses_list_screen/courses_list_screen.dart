import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/courses_list_screen/controllers/courses_list_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/courses_list_screen/widgets/my_course_card_on_list.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

@RoutePage()
class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  late CoursesListScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton(CoursesListScreenController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Meus Cursos",
          maxLines: 2,
          style: TextTheme.of(context).titleMedium,
        ),
        automaticallyImplyLeading: true,
      ),
      body: StreamValueBuilder<List<CourseModel>>(
        streamValue: _controller.courseStreamValue,
        onNullWidget: SizedBox.shrink(),
        builder: (context, courses) {
          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(courses.length, (index) {
                    return MyCourseCardOnList(course: courses[index]);
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<CoursesListScreenController>();
  }
}
