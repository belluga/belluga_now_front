import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_content_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CourseScreenController implements Disposable {
  CourseScreenController({
    required CourseItemModel? courseItemModel,
    this.childrenSelectedId,
  }) {
    currentCourseItemStreamValue = StreamValue<CourseItemModel>(
      defaultValue: courseItemModel,
    );
  }

  late TickerProviderStateMixin _vsync;
  int? childrenSelectedId;

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  final childrenSelectedItemStreamValue = StreamValue<CourseItemModel?>();
  
  late StreamValue<CourseItemModel> currentCourseItemStreamValue;

  final currentContentStreamValue = StreamValue<CourseContentModel?>();

  TabController get tabController {
    final bool _courseAlreadyHaveTabController = _tabControllersList.keys
        .contains(currentCourseItemStreamValue.value.id.toString());

    if (!_courseAlreadyHaveTabController) {
      _tabControllerInit();
    }
    return _tabControllersList[currentCourseItemStreamValue.value.id
        .toString()]!;
  }

  final Map<String, TabController> _tabControllersList = {};

  final tabIndexStreamValue = StreamValue<int>(defaultValue: 0);

  void changeSelectedChildren(int? index) {
    childrenSelectedId = index;
    if (index != null) {
      childrenSelectedItemStreamValue.addValue(
        currentCourseItemStreamValue.value.childrens[index],
      );
      currentContentStreamValue.addValue(
        currentCourseItemStreamValue.value.childrens[index].content,
      );
    } else {
      currentContentStreamValue.addValue(null);
    }
  }

  void _tabControllerInit() {
    _tabControllersList[currentCourseItemStreamValue.value.id.toString()] =
        TabController(length: _getTabCount(), vsync: _vsync);
    tabController.addListener(_onChangeTab);
  }

  void _onChangeTab() => tabIndexStreamValue.addValue(tabController.index);

  void init({required TickerProviderStateMixin vsync}) {
    _vsync = vsync;
    _tabControllerInit();
  }

  int _getTabCount() {
    int _intTabCaount = 0;
    _intTabCaount = currentCourseItemStreamValue.value.childrens.isNotEmpty
        ? _intTabCaount + 1
        : _intTabCaount;

    _intTabCaount = currentCourseItemStreamValue.value.files.isNotEmpty
        ? _intTabCaount + 1
        : _intTabCaount;

    return _intTabCaount;
  }

  @override
  FutureOr onDispose() {
    tabIndexStreamValue.dispose();
    currentCourseItemStreamValue.dispose();
    currentContentStreamValue.dispose();
    // currentSelectedItem.dispose();
    tabController.dispose();
  }
}
