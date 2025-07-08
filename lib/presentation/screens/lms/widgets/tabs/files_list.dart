import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/empty_list.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/file_card.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilesList extends StatefulWidget {
  const FilesList({super.key});

  @override
  State<FilesList> createState() => _DisciplinesListState();
}

class _DisciplinesListState extends State<FilesList> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.currentCourseItemStreamValue,
      builder: (context, courseItem) {
        if (courseItem.files.isNotEmpty) {
          return EmptyListMessage();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            children: List.generate(
              courseItem.files.length,
              (index) =>
                  FileCard(fileModel: courseItem.files[index], index: index),
            ),
          ),
        );
      },
    );
  }
}
