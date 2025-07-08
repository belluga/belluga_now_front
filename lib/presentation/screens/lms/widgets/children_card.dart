import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/controllers/course_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ChildrenCard extends StatefulWidget {
  final CourseItemModel courseItemModel;
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
        child: StreamValueBuilder<int?>(
          streamValue: _controller.currentSelectedItem,
          builder: (context, selectedItem) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceDim,
                border: selectedItem == widget.index
                    ? BoxBorder.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1,
                      )
                    : null,
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImageWithProgressIndicator(
                    thumb: widget.courseItemModel.thumb,
                  ),
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
            );
          },
        ),
      ),
    );
  }

  void _navigateToItem() {
    print("_navigateToItem");
    print(widget.courseItemModel.childrens.isNotEmpty);
    if (widget.courseItemModel.childrens.isNotEmpty) {
      _navigateToChildren();
    } else {
      _navigateToSibling();
    }
  }

  void _navigateToChildren() {
    print("_navigateToChildren");
    GetIt.I.pushNewScope(scopeName: widget.courseItemModel.id.toString());
    context.router.push(CourseRoute(courseItemModel: widget.courseItemModel));
  }

  void _navigateToSibling() {
    print("_navigateToSibling");
    if(widget.index != _controller.currentSelectedItem.value){
      _controller.changeSelectedItem(widget.index);
    }else{
      _controller.changeSelectedItem(null);
    }
    
    // _controller.changeCurrentCourseItem(widget.courseItemModel);
  }
}
