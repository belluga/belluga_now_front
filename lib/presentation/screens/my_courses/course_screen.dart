import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/tabs/disciplines_list.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/lesson_tile.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/widgets/video_player.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

@RoutePage()
class CourseScreen extends StatefulWidget {
  final MongoIDValue courseId;

  const CourseScreen({super.key, required this.courseId});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen>
    with TickerProviderStateMixin {
  late CourseScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<CourseScreenController>(
      CourseScreenController(courseId: widget.courseId),
    );
    _controller.init(tabLength: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamValueBuilder<CourseModel>(
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
                  // Tab 1: Aulas (Scrollable List)
                  DisciplinesList(),
                  // const Center(child: Text('Nenhum arquivo encontrado.')),
                  // Tab 2: Arquivos (Placeholder)
                  const Center(child: Text('Nenhum arquivo encontrado.')),
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
    GetIt.I.unregister<CourseScreenController>();
  }
}
