import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/content_video_player_controller.dart';

class CourseScreenController implements Disposable {
  final TickerProviderStateMixin vsync;

  CourseScreenController({required this.vsync});

  final contentVideoPlayerController = ContentVideoPlayerController();

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  late TabController tabController;

  final tabIndexStreamValue = StreamValue<int>(defaultValue: 0);

  bool get parentExists =>
      currentCourseItemStreamValue.value?.parent != null;

  Future<void> backToParent() async {
    final String? _courseId =
        currentCourseItemStreamValue.value?.parent?.id.value;
    
    if(_courseId == null) {
      throw Exception('Parent course ID is null');
    }
    
    changeCurrentCourseItem(_courseId);
  }

  Future<void> setCourse(String courseItemId) async {
    await _coursesRepository.getMyCoursesDashboardSummary();
    await _courseItemInit(courseItemId);
    _tabControllerInit();
  }

  Future<void> _courseItemInit(String courseId) async {
    final _courseItemModel = await _coursesRepository.courseItemGetDetails(
      courseId,
    );
    currentCourseItemStreamValue.addValue(_courseItemModel);
  }

  void _tabControllerInit() {
    TabController(length: _getTabCount(), vsync: vsync);
    tabController = TabController(length: _getTabCount(), vsync: vsync);
    tabController.addListener(_onChangeTab);
  }

  Future<void> changeCurrentCourseItem(String courseItemId) async {
    await cleanCurrentCourseItem();
    await setCourse(courseItemId);
    _tabControllerInit();
  }

  Future<void> cleanCurrentCourseItem() async {
    currentCourseItemStreamValue.addValue(null);
    tabController.dispose();
    contentVideoPlayerController.clearLesson();
  }

  void _onChangeTab() => tabIndexStreamValue.addValue(tabController.index);

  int _getTabCount() {
    int _intTabCaount = 0;
    _intTabCaount = currentCourseItemStreamValue.value!.childrens.isNotEmpty
        ? _intTabCaount + 1
        : _intTabCaount;

    _intTabCaount = currentCourseItemStreamValue.value!.files.isNotEmpty
        ? _intTabCaount + 1
        : _intTabCaount;

    return _intTabCaount;
  }

  Future<void> initializePlayer() async {
    await contentVideoPlayerController.changeLesson(
      currentCourseItemStreamValue.value!,
    );
    await contentVideoPlayerController.initializePlayer();
  }

  @override
  FutureOr onDispose() {
    tabIndexStreamValue.dispose();
    currentCourseItemStreamValue.dispose();
    tabController.dispose();
    contentVideoPlayerController.onDispose();
  }
}
