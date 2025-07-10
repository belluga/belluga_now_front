import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/presentation/common/widgets/image_with_progress_indicator.dart';

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
        child: Stack(
          children: [
            ImageWithProgressIndicator(
              thumb: widget.courseModel.thumb,
              width: double.infinity,
              height: 200,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 4,
                          children: List.generate(
                            widget.courseModel.categories.length,
                            (index) {
                              final _category = widget.courseModel.categories[index];
                              return CircleAvatar(
                                backgroundColor: _category.color.value,
                                radius: 12);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.courseModel.title.valueFormated,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextTheme.of(context).titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // SizedBox(
            //   height: 200,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       image: DecorationImage(
            //         image: NetworkImage(
            //           widget.courseModel.thumb.thumbUri.toString(),
            //         ),
            //         fit: BoxFit.cover,
            //       ),
            //     ),
            //   ),
            // ),
          ],
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
