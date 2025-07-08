import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/controllers/course_screen_controller.dart';
import 'package:get_it/get_it.dart';

class CourseHeaderBanner extends StatefulWidget {
  const CourseHeaderBanner({super.key});

  @override
  State<CourseHeaderBanner> createState() => _CourseHeaderBannerState();
}

class _CourseHeaderBannerState extends State<CourseHeaderBanner> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    final CourseItemModel _courseModel =
        _controller.currentCourseItemStreamValue.value;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        _courseModel.thumb.thumbUri.toString(),
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
                SafeArea(child: Row(children: [BackButton()])),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _courseModel.title.value,
                        maxLines: 2,
                        style: TextTheme.of(context).titleLarge,
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
}
