import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/presentation/screens/lms/screens/fast_tracks_list_screen/controllers/fast_tracks_list_screen_controller.dart';

class FastTracksCategoryFiltersIconCounter extends StatefulWidget {
  const FastTracksCategoryFiltersIconCounter({super.key});

  @override
  State<FastTracksCategoryFiltersIconCounter> createState() =>
      _FastTracksCategoryFiltersIconCounterState();
}

class _FastTracksCategoryFiltersIconCounterState
    extends State<FastTracksCategoryFiltersIconCounter> {
  final _controller = GetIt.I.get<FastTracksListScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<CourseCategoryModel>>(
      streamValue: _controller.selectedCategoriesStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (context, selectedCategories) {
        if (selectedCategories.isEmpty) {
          return SizedBox.shrink();
        }

        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: _controller.scrollToTop,
          child: Stack(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.filter_list_alt)),
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  selectedCategories.length.toString(),
                  style: TextTheme.of(context).bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
