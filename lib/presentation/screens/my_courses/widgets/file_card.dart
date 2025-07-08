import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/image_with_progress_indicator.dart';

class FileCard extends StatefulWidget {
  final CourseItemModel courseModel;
  final int index;

  const FileCard({super.key, required this.courseModel, required this.index});

  @override
  State<FileCard> createState() => _DisciplineCardState();
}

class _DisciplineCardState extends State<FileCard> {
  @override
  Widget build(BuildContext context) {
    final _index = widget.index + 1;

    return Card(
      child: Container(
        color: Theme.of(context).colorScheme.surfaceDim,
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageWithProgressIndicator(thumb: widget.courseModel.thumb),
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_index. ${widget.courseModel.title.valueFormated}",
                      maxLines: 2,
                      style: TextTheme.of(context).labelMedium,
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(value: 0.55),
                    SizedBox(height: 8),
                    Text(
                      widget.courseModel.description.valueFormated,
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
    );
  }
}
