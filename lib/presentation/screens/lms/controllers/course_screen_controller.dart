import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_content_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CourseScreenController implements Disposable {
  CourseScreenController({required CourseItemModel courseItemModel}) {
    currentCourseItemStreamValue = StreamValue<CourseItemModel>(
      defaultValue: courseItemModel,
    );
    currentContentStreamValue = StreamValue<CourseContentModel?>(
      defaultValue: courseItemModel.content,
    );
  }

  late TickerProviderStateMixin _vsync;

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  late StreamValue<CourseItemModel> currentCourseItemStreamValue;
  late StreamValue<CourseContentModel?> currentContentStreamValue;
  final currentSelectedItem = StreamValue<int?>();

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

  void changeSelectedItem(int? index) {
    currentSelectedItem.addValue(index);
    if (index != null) {
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
    currentSelectedItem.dispose();
    tabController.dispose();
  }
}
