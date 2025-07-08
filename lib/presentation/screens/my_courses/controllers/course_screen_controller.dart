import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class LessonScreenController implements Disposable {
  LessonScreenController({required this.courseId});

  final MongoIDValue courseId;

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<CourseItemModel?> get courseStreamValue =>
      _coursesRepository.currentCourseItemStreamValue;

  late TabController tabController;

  final tabIndexStreamValue = StreamValue<int>(defaultValue: 0);

  void _tabControllerInit(int tabLength, TickerProviderStateMixin vsync) {
    tabController = TabController(length: tabLength, vsync: vsync);
    tabController.addListener(_onChangeTab);
  }

  void _onChangeTab() => tabIndexStreamValue.addValue(tabController.index);

  void init({required int tabLength, required TickerProviderStateMixin vsync}) {
    _getCourse();
    _tabControllerInit(tabLength, vsync);
  }

  Future<void> _getCourse() async {
    await _coursesRepository.getCourseDetails(courseId.value);
  }

  @override
  FutureOr onDispose() {
    //
  }
}
