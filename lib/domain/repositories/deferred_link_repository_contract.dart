import 'package:belluga_now/domain/repositories/deferred_link_capture_result.dart';

export 'package:belluga_now/domain/repositories/deferred_link_capture_result.dart';
export 'package:belluga_now/domain/repositories/deferred_link_capture_status.dart';
export 'package:belluga_now/domain/repositories/value_objects/deferred_link_repository_contract_values.dart';

abstract class DeferredLinkRepositoryContract {
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode();
}
