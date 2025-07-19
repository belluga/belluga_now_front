import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_category_model.dart';

class CategoryChip extends StatelessWidget {
  final CourseCategoryModel category;

  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {

    

    return Chip(
      avatar: Icon(
        Icons.category_outlined,
        size: 16,
        color: category.color.value.computeLuminance() > 0.5
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      visualDensity: VisualDensity.compact,
      label: Text(
        category.name.value,
        style: TextTheme.of(context).labelSmall?.copyWith(
          color: category.color.value.computeLuminance() > 0.5
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor: category.color.value,
    );
  }
}
