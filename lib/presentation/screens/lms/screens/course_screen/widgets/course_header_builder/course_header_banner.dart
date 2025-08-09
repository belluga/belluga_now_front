import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/course_item_model.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:belluga_now/presentation/screens/lms/widgets/category_chip.dart';

class CourseHeaderBanner extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const CourseHeaderBanner({super.key, required this.courseItemModel});

  @override
  State<CourseHeaderBanner> createState() => _CourseHeaderBannerState();
}

class _CourseHeaderBannerState extends State<CourseHeaderBanner> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          ClipRRect(
            // borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        widget.courseItemModel.thumb.thumbUri.toString(),
                      ),
                    ),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.transparent),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceDim.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SafeArea(
                  bottom: false,
                  child: Row(
                    children: [BackButton(onPressed: _backNavigation)],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.courseItemModel.title.value,
                            maxLines: 2,
                            style: TextTheme.of(context).headlineSmall,
                          ),
                          Builder(
                            builder: (context) {
                              final List<CourseCategoryModel>? _categories =
                                  widget.courseItemModel.categories;

                              if (_categories == null || _categories.isEmpty) {
                                return SizedBox.shrink();
                              }

                              return Wrap(
                                spacing: 8.0,
                                alignment: WrapAlignment.end,
                                children: _categories
                                    .map(
                                      (category) =>
                                          CategoryChip(category: category),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _backNavigation() {
    if (_controller.parentExists) {
      return _navigateToParent();
    }

    return _pop();
  }

  void _navigateToParent() => _controller.backToParent();

  void _pop() => context.router.pop();
}
