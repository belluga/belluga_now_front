import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/courses/course_base_model.dart';
import 'package:unifast_portal/presentation/common/widgets/image_with_progress_indicator.dart';

class MyCourseCardOnList extends StatefulWidget {
  final CourseBaseModel course;

  const MyCourseCardOnList({super.key, required this.course});

  @override
  State<MyCourseCardOnList> createState() => _MyCourseCardOnListState();
}

class _MyCourseCardOnListState extends State<MyCourseCardOnList> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: InkWell(
        onTap: _navigateToCourse,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 200),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.course.thumb.thumbUri.valueFormated),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                ImageWithProgressIndicator(thumb: widget.course.thumb),
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
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
        ),
      ),
    );
  }

  Future<void> _navigateToCourse() async {
    context.router.push(CourseRoute(courseItemId: widget.course.id.toString()));
  }
}
