enum DeferredLinkCaptureStatus {
  captured,
  notCaptured,
  skipped,
}

class DeferredLinkCaptureResult {
  const DeferredLinkCaptureResult({
    required this.status,
    this.code,
    this.storeChannel,
    this.failureReason,
  });

  final DeferredLinkCaptureStatus status;
  final String? code;
  final String? storeChannel;
  final String? failureReason;

  bool get isCaptured =>
      status == DeferredLinkCaptureStatus.captured &&
      code != null &&
      code!.isNotEmpty;

  bool get shouldTrackFailure =>
      status == DeferredLinkCaptureStatus.notCaptured &&
      failureReason != null &&
      failureReason!.isNotEmpty;
}

abstract class DeferredLinkRepositoryContract {
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode();
}
