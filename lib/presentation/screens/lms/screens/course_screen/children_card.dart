import 'package:flutter/material.dart';
import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';

class ChildrenCard extends StatefulWidget {
  final CourseBaseModel courseItemModel;
  final int index;

  const ChildrenCard({
    super.key,
    required this.courseItemModel,
    required this.index,
  });

  @override
  State<ChildrenCard> createState() => _ChildrenCardState();
}

class _ChildrenCardState extends State<ChildrenCard> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    final _index = widget.index + 1;

    return Card(
      child: InkWell(
        onTap: _navigateToItem,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceDim,
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageWithProgressIndicator(thumb: widget.courseItemModel.thumb),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$_index. ${widget.courseItemModel.title.valueFormated}",
                        maxLines: 2,
                        style: TextTheme.of(context).labelMedium,
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.55),
                      SizedBox(height: 8),
                      Text(
                        widget.courseItemModel.description.valueFormated,
                        maxLines: 3,
                        style: TextTheme.of(
                          context,
                        ).bodySmall?.copyWith(fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToItem() {
    // if (widget.courseItemModel.childrens.isNotEmpty) {
    _navigateToChildren();
    // } else {
    //   _navigateToSibling();
    // }
  }

  void _navigateToChildren() {
    _controller.changeCurrentCourseItem(widget.courseItemModel.id.value);
  }

  // void _navigateToSibling() {
  //   _controller.changeSelectedChildren(widget.index);
  //   context.router.replace(
  //     CourseRoute(
  //       key: ValueKey(widget.courseItemModel.id.toString()),
  //       courseItemId: widget.courseItemModel.id.toString(),
  //     ),
  //   );
  // }
}
