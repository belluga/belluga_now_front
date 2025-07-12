import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/controllers/fast_tracks_list_screen_controller.dart';

class CategoryCard extends StatefulWidget {
  final CourseCategoryModel categoryModel;

  const CategoryCard({super.key, required this.categoryModel});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  final _controller = GetIt.I.get<FastTracksListScreenController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceDim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _filterByCategory,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  color: widget.categoryModel.color.value,
                ),
                child: Icon(Icons.category),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.categoryModel.name.valueFormated,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        softWrap: true,
                      ), // Adjust the text style as needed
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

  void _filterByCategory() =>
      _controller.filterByCategory(widget.categoryModel);
}
