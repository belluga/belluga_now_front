import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/file_card.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilesList extends StatefulWidget {
  const FilesList({super.key});

  @override
  State<FilesList> createState() => _DisciplinesListState();
}

class _DisciplinesListState extends State<FilesList> {
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
              (index) =>
                  FileCard(courseModel: course.childrens[index], index: index),
            ),
          );
        },
      ),
    );
  }
}
