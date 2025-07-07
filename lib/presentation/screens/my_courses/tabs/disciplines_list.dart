import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/discipline_card.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DisciplinesList extends StatefulWidget {
  const DisciplinesList({super.key});

  @override
  State<DisciplinesList> createState() => _DisciplinesListState();
}

class _DisciplinesListState extends State<DisciplinesList> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 8),
      child: StreamValueBuilder<CourseModel>(
        streamValue: _controller.courseStreamValue,
        onNullWidget: SizedBox.shrink(),
        builder: (context, course) {
          return Column(
            children: List.generate(
              course.disciplines.length,
              (index) => DisciplineCard(
                disciplineModel: course.disciplines[index],
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}
