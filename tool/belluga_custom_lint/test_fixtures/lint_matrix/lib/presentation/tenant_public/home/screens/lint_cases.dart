import 'package:get_it/get_it.dart';

import 'package:lint_matrix_fixture/presentation/tenant_public/home/controllers/home_controller.dart';
import 'package:lint_matrix_fixture/presentation/tenant_public/map/controllers/map_controller.dart';

// expect_lint: ui_dto_import_forbidden
import 'package:lint_matrix_fixture/infrastructure/dal/dto/fake_dto.dart';

class DummyController {
  void refresh() {}
}

class StreamValue<T> {
  StreamValue({T? defaultValue});
}

class DummyRepositoryContract {}

class AppData {}

class LifecycleController {
  void dispose() {}
}

class UiLifecycleCase {
  final LifecycleController _controller = LifecycleController();

  void onDispose() {
    // expect_lint: module_scoped_controller_dispose_forbidden
    _controller.dispose();
  }
}

class UiStreamOwner {
  // expect_lint: ui_streamvalue_ownership_forbidden
  final owned = StreamValue<int>(defaultValue: 0);
}

class FutureBuilder<T> {}

class StreamBuilder<T> {}

class UiBuilderCase {
  // expect_lint: ui_future_stream_builder_forbidden
  final FutureBuilder<int> futureBuilder = FutureBuilder<int>();

  // expect_lint: ui_future_stream_builder_forbidden
  final StreamBuilder<int> streamBuilder = StreamBuilder<int>();
}

class UiGetItCase {
  void resolve() {
    // expect_lint: ui_getit_non_controller_forbidden
    GetIt.I.get<AppData>();

    // expect_lint: ui_direct_repository_service_resolution_forbidden
    GetIt.I.get<DummyRepositoryContract>();

    GetIt.I.get<DummyController>();
    GetIt.I.get<HomeController>();

    // expect_lint: ui_cross_feature_controller_resolution_forbidden
    GetIt.I.get<MapController>();
  }
}

class UiDtoUsageCase {
  FakeDto read() => const FakeDto();
}
