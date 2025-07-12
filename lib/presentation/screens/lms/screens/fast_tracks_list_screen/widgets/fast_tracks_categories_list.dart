import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';
import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/presentation/common/widgets/dashboard_title_row.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/controllers/fast_tracks_list_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/widgets/category_card.dart';

class FastTracksCategoriesList extends StatefulWidget {
  const FastTracksCategoriesList({super.key});

  @override
  State<FastTracksCategoriesList> createState() =>
      _FastTracksCategoriesListState();
}

class _FastTracksCategoriesListState extends State<FastTracksCategoriesList> {
  final _controller = GetIt.I.get<FastTracksListScreenController>();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardTitleRow(
              title: "Categorias",
              showAllLabel: "Ver todas",
              onShowAllPressed: () {},
            ),
          ),
          StreamValueBuilder<List<CourseCategoryModel>>(
            streamValue: _controller.categoriesStreamValue,
            onNullWidget: SliverToBoxAdapter(
              child: const Center(child: CircularProgressIndicator()),
            ),
            builder: (context, categories) {
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 3.5,
                  crossAxisCount: 2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  if (index >= categories.length) {
                    return null;
                  }
          
                  final _category = categories[index];
          
                  return CategoryCard(categoryModel: _category,);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
