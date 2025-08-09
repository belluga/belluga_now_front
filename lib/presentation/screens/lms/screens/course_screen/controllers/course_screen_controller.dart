import 'dart:async';

import 'package:flutter/material.dart';
import 'package:belluga_now/domain/courses/course_item_model.dart';
import 'package:belluga_now/domain/notes/note_model.dart';
import 'package:belluga_now/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/repositories/notes_repository_contract.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/content_video_player_controller.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/tab_content_type.dart';

class CourseScreenController implements Disposable {
  final TickerProviderStateMixin vsync;

  CourseScreenController({required this.vsync});

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();
  final _notesRepository = GetIt.I.get<NotesRepositoryContract>();

  final contentVideoPlayerController = ContentVideoPlayerController();

  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  late StreamValue<List<NoteModel>?> notesStreamValue =
      _notesRepository.notesSteamValue;

  late TabController tabController;

  final tabIndexStreamValue = StreamValue<int>(defaultValue: 0);
  final tabContentTypeStreamValue = StreamValue<TabContentType?>();

  bool get parentExists => currentCourseItemStreamValue.value?.parent != null;

  Future<void> backToParent() async {
    final String? _courseId =
        currentCourseItemStreamValue.value?.parent?.id.value;

    if (_courseId == null) {
      throw Exception('Parent course ID is null');
    }

    changeCurrentCourseItem(_courseId);
  }

  Future<void> setCourse(String courseItemId) async {
    await _coursesRepository.getMyCoursesDashboardSummary();
    await _courseItemInit(courseItemId);
    _tabControllerInit();
  }

  Future<void> getNotes() async {
    final courseItemId = currentCourseItemStreamValue.value?.id.value;

    if (courseItemId == null) {
      throw Exception('Course item ID is null');
    }

    await _notesRepository.getNotes(courseItemId);
  }

  Future<void> _courseItemInit(String courseId) async {
    final _courseItemModel = await _coursesRepository.courseItemGetDetails(
      courseId,
    );
    currentCourseItemStreamValue.addValue(_courseItemModel);
  }

  void _tabControllerInit() {
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

  void _onChangeTab() {
    if (tabController.indexIsChanging) return;

    tabIndexStreamValue.addValue(tabController.index);

    if (tabController.index <= tabContentTypes.length) {
      tabContentTypeStreamValue.addValue(tabContentTypes[tabController.index]);
    }
  }

  final List<TabContentType> tabContentTypes = [];

  int get getTabContentIndex =>
      tabContentTypes.indexOf(tabContentTypeStreamValue.value!);

  int _getTabCount() {
    tabContentTypes.clear();

    if (currentCourseItemStreamValue.value!.childrens.isNotEmpty) {
      tabContentTypes.add(TabContentType.childrens);
    }

    if (currentCourseItemStreamValue.value!.files.isNotEmpty) {
      tabContentTypes.add(TabContentType.files);
    }

    if(currentCourseItemStreamValue.value!.hasVideoContent) {
      tabContentTypes.add(TabContentType.notes);
    }

    tabContentTypeStreamValue.addValue(tabContentTypes.first);

    return tabContentTypes.length;
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
