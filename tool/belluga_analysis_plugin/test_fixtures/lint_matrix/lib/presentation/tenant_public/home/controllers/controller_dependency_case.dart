import 'package:get_it/get_it.dart';

import 'other_feature_controller.dart';

class ControllerDependencyCaseController {
  ControllerDependencyCaseController({
    // expect_lint: controller_controller_dependency_forbidden
    OtherFeatureController? delegate,
  }) : _delegate = delegate ??
            // expect_lint: controller_controller_dependency_forbidden
            GetIt.I.get<OtherFeatureController>();

  final OtherFeatureController _delegate;

  void touch() {
    _delegate.hashCode;
  }
}

class ControllerDependencyAllowedLocalHelperCaseController {
  final _LocalHelperController helper = _LocalHelperController();

  void touch() {
    helper.hashCode;
  }
}

class _LocalHelperController {
  const _LocalHelperController();
}
