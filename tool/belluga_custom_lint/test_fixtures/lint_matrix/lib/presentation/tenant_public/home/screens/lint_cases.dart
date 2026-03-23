// ignore_for_file: unused_element

import 'package:get_it/get_it.dart';

import 'package:lint_matrix_fixture/presentation/tenant_public/home/controllers/home_controller.dart';
import 'package:lint_matrix_fixture/presentation/tenant_public/map/controllers/map_controller.dart';

// expect_lint: ui_dto_import_forbidden
import 'package:lint_matrix_fixture/infrastructure/dal/dto/fake_dto.dart';

class _DummyController {
  void refresh() {}
}

class StreamValue<T> {
  StreamValue({T? defaultValue});
}

// expect_lint: multi_public_class_file_warning
class StreamValueBuilder<T> {
  StreamValueBuilder({
    required Object streamValue,
    required T Function(Object context, T value) builder,
    Object? onNullWidget,
  });
}

class _DummyRepositoryContract {}

class _AppData {}

class _LifecycleController {
  void dispose() {}
}

class _UiLifecycleCase {
  final _LifecycleController _controller = _LifecycleController();

  void onDispose() {
    // expect_lint: module_scoped_controller_dispose_forbidden
    _controller.dispose();
  }
}

class _UiStreamOwner {
  // expect_lint: ui_streamvalue_ownership_forbidden
  final owned = StreamValue<int>(defaultValue: 0);
}

// expect_lint: multi_public_class_file_warning
class FutureBuilder<T> {}

// expect_lint: multi_public_class_file_warning
class StreamBuilder<T> {}

class _UiBuilderCase {
  // expect_lint: ui_future_stream_builder_forbidden
  final FutureBuilder<int> futureBuilder = FutureBuilder<int>();

  // expect_lint: ui_future_stream_builder_forbidden
  final StreamBuilder<int> streamBuilder = StreamBuilder<int>();

  StreamValueBuilder<String?> streamValueBuilderWithNullCheck() {
    return StreamValueBuilder<String?>(
      streamValue: Object(),
      onNullWidget: Object(),
      builder: (context, value) {
        // expect_lint: ui_streamvalue_builder_null_check_forbidden
        if (value == null) {
          return '';
        }
        return value;
      },
    );
  }
}

class _UiGetItCase {
  void resolve() {
    // expect_lint: ui_getit_non_controller_forbidden
    GetIt.I.get<_AppData>();

    // expect_lint: ui_direct_repository_service_resolution_forbidden
    GetIt.I.get<_DummyRepositoryContract>();

    GetIt.I.get<_DummyController>();
    GetIt.I.get<HomeController>();

    // expect_lint: ui_cross_feature_controller_resolution_forbidden
    GetIt.I.get<MapController>();
  }
}

class _UiDtoUsageCase {
  FakeDto read() => const FakeDto();
}
