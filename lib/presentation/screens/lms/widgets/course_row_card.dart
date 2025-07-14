import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/courses/course_base_model.dart';
import 'package:unifast_portal/presentation/common/widgets/image_with_progress_indicator.dart';

class CourseRowCard extends StatefulWidget {
  final CourseBaseModel course;

  const CourseRowCard({super.key, required this.course});

  @override
  State<CourseRowCard> createState() => _CourseRowCardState();
}

class _CourseRowCardState extends State<CourseRowCard> {
  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: InkWell(
        onTap: _navigateToCourse,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageWithProgressIndicator(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              thumb: widget.course.thumb,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.course.title.valueFormated,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          widget.course.teachers.first.name.valueFormated,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _navigateToCourse,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Continuar",
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCourse() async {
    GetIt.I.pushNewScope(scopeName: widget.course.id.toString());
    context.router.push(CourseRoute(courseItemId: widget.course.id.toString()));
  }
}
