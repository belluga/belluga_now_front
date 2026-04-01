export 'deferred_link_capture_code_value.dart';
export 'deferred_link_failure_reason_value.dart';
export 'deferred_link_store_channel_value.dart';

import 'deferred_link_capture_code_value.dart';
import 'deferred_link_failure_reason_value.dart';
import 'deferred_link_store_channel_value.dart';

DeferredLinkCaptureCodeValue deferredLinkCode(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is DeferredLinkCaptureCodeValue) {
    return raw;
  }
  return DeferredLinkCaptureCodeValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

DeferredLinkStoreChannelValue deferredLinkStoreChannel(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is DeferredLinkStoreChannelValue) {
    return raw;
  }
  return DeferredLinkStoreChannelValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

DeferredLinkFailureReasonValue deferredLinkFailureReason(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is DeferredLinkFailureReasonValue) {
    return raw;
  }
  return DeferredLinkFailureReasonValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}
