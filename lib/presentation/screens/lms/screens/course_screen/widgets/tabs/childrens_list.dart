import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/children_card.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ChildrensList extends StatefulWidget {
  const ChildrensList({super.key});

  @override
  State<ChildrensList> createState() => _ChildrensListState();
}

class _ChildrensListState extends State<ChildrensList> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 8),
      child: StreamValueBuilder(
        streamValue: _controller.currentCourseItemStreamValue,
        builder: (context, courseItem) {
          return Column(
            children: List.generate(
              courseItem.childrens.length,
              (index) => ChildrenCard(
                courseItemModel: courseItem.childrens[index],
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}
