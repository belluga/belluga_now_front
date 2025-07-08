import 'package:flutter_laravel_backend_boilerplate/domain/repositories/external_courses_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/view_models/external_courses_summary.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ExternalCourseDashboardController {
  final String storagePreferenceUrlNavigationKey =
      "external_course_url_navigation_preference";

  final _externalCoursesRepository = GetIt.I
      .get<ExternalCoursesRepositoryContract>();

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  StreamValue<ExternalCoursesSummary?> get externalCoursesSummaryStreamValue {
    return _externalCoursesRepository.summarySteamValue;
  }

  final navigationPreferenceStreamValue = StreamValue<bool>(defaultValue: false);

  Future<void> init() async {
    await _getExternalCoursesSummary();
    await _getUrlNavigationPreference();
  }

  Future<void> _getExternalCoursesSummary() async =>
      await _externalCoursesRepository.getDashboardSummary();

  //TODO: Centralize all User Preferences in User Profile
  Future<bool> _getUrlNavigationPreference() async {
    bool dontAskAgain =
        await storage.read(key: storagePreferenceUrlNavigationKey) == "true";
    navigationPreferenceStreamValue.addValue(dontAskAgain);
    return dontAskAgain;
  }

  Future<void> saveUrlNavigationPreference(bool? value) async {
    bool dontAskAgain = (value ?? false);

    await storage.write(
      key: storagePreferenceUrlNavigationKey,
      value: dontAskAgain.toString(),
    );

    navigationPreferenceStreamValue.addValue(dontAskAgain);
  }
}
