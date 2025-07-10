import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';

class FastTrackCard extends StatefulWidget {
  final CourseModel courseModel;

  const FastTrackCard({super.key, required this.courseModel});

  @override
  State<FastTrackCard> createState() => _FastTrackCardState();
}

class _FastTrackCardState extends State<FastTrackCard> {
  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: InkWell(
        onTap: _navigateToCourse,
        child: SizedBox(
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  widget.courseModel.thumb.thumbUri.toString(),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCourse() async {
    GetIt.I.pushNewScope(scopeName: widget.courseModel.id.toString());
    context.router.push(
      CourseRoute(courseItemId: widget.courseModel.id.toString()),
    );
  }
}
