import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CourseScreenController implements Disposable {
  final String courseItemId;
  final TickerProviderStateMixin vsync;

  CourseScreenController({required this.courseItemId, required this.vsync}) {
    _init();
  }

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  final childrenSelectedItemIDStreamValue = StreamValue<int?>();

  final childrenSelectedItemStreamValue = StreamValue<CourseItemModel?>();

  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();

  late TabController tabController;

  final tabIndexStreamValue = StreamValue<int>(defaultValue: 0);

  Future<void> _init() async {
    await _coursesRepository.init();
    await _courseItemInit();
    _tabControllerInit();
  }

  Future<void> _courseItemInit() async {
    final _courseItemModel = await _coursesRepository.courseItemGetDetails(
      courseItemId,
    );
    currentCourseItemStreamValue.addValue(_courseItemModel);
  }

  void _tabControllerInit() {
    TabController(length: _getTabCount(), vsync: vsync);
    tabController = TabController(length: _getTabCount(), vsync: vsync);
    tabController.addListener(_onChangeTab);
  }


  void changeSelectedChildren(int? index) {
    if (index == null) {
      childrenSelectedItemIDStreamValue.addValue(null);
      childrenSelectedItemStreamValue.addValue(null);
      return;
    }

    childrenSelectedItemIDStreamValue.addValue(index);

    childrenSelectedItemStreamValue.addValue(
      currentCourseItemStreamValue.value!.childrens[index],
    );
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

  @override
  FutureOr onDispose() {
    tabIndexStreamValue.dispose();
    currentCourseItemStreamValue.dispose();
    tabController.dispose();
  }
}
