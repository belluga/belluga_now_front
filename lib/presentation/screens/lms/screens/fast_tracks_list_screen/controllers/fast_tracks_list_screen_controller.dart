import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FastTracksListScreenController implements Disposable {
  FastTracksListScreenController() {
    filteredCoursesStreamValue = StreamValue<List<CourseModel>?>(
      defaultValue: _courseStreamValue.value,
    );

    _courseStreamValue.stream.listen(listenCoursesList);
    selectedCategoriesStreamValue.stream.listen(listenCategoriesList);
  }

  Future<void> init() async {
    getFastTracksCategories();
    getlastCreatedFastTracks();
    getFastTracksList();
  }

  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  final scrollController = ScrollController();

  StreamValue<List<CourseModel>?> get _courseStreamValue =>
      _coursesRepository.fastTracksListStreamValue;

  StreamValue<List<CourseCategoryModel>?> get categoriesStreamValue =>
      _coursesRepository.fastTracksCategoriesListStreamValue;

  StreamValue<List<CourseModel>?> get lastCreatedFastTracksStreamValue =>
      _coursesRepository.lastCreatedfastTracksStreamValue;

  late StreamValue<List<CourseModel>?> filteredCoursesStreamValue;

  final selectedCategoriesStreamValue =
      StreamValue<List<CourseCategoryModel>?>();

  Future<void> getFastTracksList() async {
    await _coursesRepository.getFastTracksList();
  }

  Future<void> getFastTracksCategories() async {
    await _coursesRepository.getFastTracksCategories();
  }

  Future<void> getlastCreatedFastTracks() async {
    await _coursesRepository.getFastTracksLastCreatedList();
  }

  Future<void> filterByCategory(CourseCategoryModel category) async {
    final _selectedCategories = selectedCategoriesStreamValue.value ?? [];
    if (_selectedCategories.contains(category)) {
      // If the category is already selected, remove it
      _selectedCategories.remove(category);
    } else {
      // If the category is not selected, add it
      _selectedCategories.add(category);
    }

    selectedCategoriesStreamValue.addValue(_selectedCategories);
  }

  void listenCategoriesList(List<CourseCategoryModel>? categories) {
    final _allCourses = _courseStreamValue.value ?? [];
    final _categoriesSelected = categories;

    if (_categoriesSelected == null || _categoriesSelected.isEmpty) {
      filteredCoursesStreamValue.addValue(_allCourses);
      return;
    }

    final filtered = _allCourses.where((course) {
      return _categoriesSelected.any(
        (category) =>
            course.categories?.any(
              (courseCategory) => courseCategory.id == category.id,
            ) ??
            false,
      );
    }).toList();

    filteredCoursesStreamValue.addValue(filtered);
  }

  void listenCoursesList(List<CourseModel>? courses) {
    filteredCoursesStreamValue.addValue(courses);
  }

  Future<void> scrollToTop() async {
    if (scrollController.hasClients) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  FutureOr onDispose() {
    //
  }
}
