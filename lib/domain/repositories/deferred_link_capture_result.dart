import 'package:belluga_now/domain/repositories/deferred_link_capture_status.dart';
import 'package:belluga_now/domain/repositories/value_objects/deferred_link_capture_code_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/deferred_link_failure_reason_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/deferred_link_store_channel_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/deferred_link_target_path_value.dart';

class DeferredLinkCaptureResult {
  const DeferredLinkCaptureResult({
    required this.status,
    this.codeValue,
    this.targetPathValue,
    this.storeChannelValue,
    this.failureReasonValue,
  });

  final DeferredLinkCaptureStatus status;
  final DeferredLinkCaptureCodeValue? codeValue;
  final DeferredLinkTargetPathValue? targetPathValue;
  final DeferredLinkStoreChannelValue? storeChannelValue;
  final DeferredLinkFailureReasonValue? failureReasonValue;

  String? get code {
    final value = codeValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get targetPath {
    final value = targetPathValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get storeChannel {
    final value = storeChannelValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get failureReason {
    final value = failureReasonValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  bool get isCaptured =>
      status == DeferredLinkCaptureStatus.captured && targetPath != null;

  bool get shouldTrackFailure =>
      status == DeferredLinkCaptureStatus.notCaptured && failureReason != null;
}
