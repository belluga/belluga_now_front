class DeferredLinkResolutionDto {
  const DeferredLinkResolutionDto({
    required this.status,
    this.code,
    this.storeChannel,
    this.failureReason,
  });

  final String status;
  final String? code;
  final String? storeChannel;
  final String? failureReason;
}
