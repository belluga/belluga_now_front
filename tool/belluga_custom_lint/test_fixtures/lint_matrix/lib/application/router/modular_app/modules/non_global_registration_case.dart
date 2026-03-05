import 'package:get_it/get_it.dart';

class FeatureController {}

void registerFeatureScope() {
  // Not a sanctioned global registration file path; this rule must not fire here.
  GetIt.I.registerFactory<FeatureController>(() => FeatureController());
}
