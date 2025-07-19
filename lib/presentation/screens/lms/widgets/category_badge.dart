import 'package:flutter/material.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';

class CategoryBadge extends StatelessWidget {
  final CourseCategoryModel category;

  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: category.color.value,
      radius: 16,
      child: Icon(
        Icons.category_outlined,
        size: 16,
        color: category.color.value.computeLuminance() > 0.5
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
