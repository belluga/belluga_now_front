import 'dart:async';

import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FastTracksListScreenController implements Disposable {
  final _coursesRepository = GetIt.I.get<CoursesRepositoryContract>();

  StreamValue<List<CourseModel>?> get courseStreamValue =>
      _coursesRepository.fastTracksListSteamValue;

  StreamValue<List<CourseCategoryModel>?> get categoriesStreamValue =>
      _coursesRepository.fastTracksCategoriesListSteamValue;

  StreamValue<List<CourseModel>?> get lastCreatedFastTracksStreamValue =>
      _coursesRepository.lastCreatedfastTracksSteamValue;

  Future<void> getFastTracksCategories() async {
    await _coursesRepository.getFastTracksCategories();
  }

  Future<void> getlastCreatedFastTracks() async {
    await _coursesRepository.getFastTracksLastCreatedList();
  }

  Future<void> filterByCategory(CourseCategoryModel catetory) async {}

  @override
  FutureOr onDispose() {
    //
  }
}
