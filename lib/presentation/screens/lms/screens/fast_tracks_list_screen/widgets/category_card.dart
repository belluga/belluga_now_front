import 'package:flutter/material.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';

class CategoryCard extends StatelessWidget {
  final CourseCategoryModel categoryModel;
  final void Function()? onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.categoryModel,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceDim,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap ?? () {},
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
                  color: categoryModel.color.value,
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
                        categoryModel.name.valueFormated,
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
}
