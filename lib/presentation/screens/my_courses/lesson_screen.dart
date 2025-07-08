import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/tabs/files_list.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/tabs/lessons_list.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/lesson_tile.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/video_player.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

@RoutePage()
class LessonScreen extends StatefulWidget {
  final MongoIDValue lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {
  late LessonScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<LessonScreenController>(
      LessonScreenController(courseId: widget.lessonId),
    );
    _controller.init(tabLength: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamValueBuilder<CourseItemModel>(
          streamValue: _controller.courseStreamValue,
          onNullWidget: SizedBox.shrink(),
          builder: (context, course) {
            return Text(
              course.title.value,
              maxLines: 2,
              style: TextTheme.of(context).titleMedium,
            );
          },
        ),
        automaticallyImplyLeading: true,
      ),

      body: Column(
        children: [
          VideoPlayer(),
          LessonTile(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceDim,
              child: TabBar(
                controller: _controller.tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                tabs: const [
                  Tab(text: 'Aulas'),
                  Tab(text: 'Arquivos'),
                  Tab(text: 'Anotações'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TabBarView(
                controller: _controller.tabController,
                children: [
                  LessonsList(),
                  FilesList(),
                  // Tab 3: Anotações (Placeholder)
                  const Center(child: Text('Nenhuma anotação encontrada.')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    GetIt.I.unregister<LessonScreenController>();
  }
}
