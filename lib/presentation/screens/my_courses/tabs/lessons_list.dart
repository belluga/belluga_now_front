import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/lesson_card.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class LessonsList extends StatefulWidget {
  const LessonsList({super.key});

  @override
  State<LessonsList> createState() => _DisciplinesListState();
}

class _DisciplinesListState extends State<LessonsList> {
  final _controller = GetIt.I.get<LessonScreenController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 8),
      child: StreamValueBuilder<CourseItemModel>(
        streamValue: _controller.courseStreamValue,
        onNullWidget: SizedBox.shrink(),
        builder: (context, course) {
          return Column(
            children: List.generate(
              course.childrens.length,
              (index) => LessonCard(
                courseModel: course.childrens[index],
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}
