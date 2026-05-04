class DeferredLinkResolutionDto {
  const DeferredLinkResolutionDto({
    required this.status,
    this.code,
    this.targetPath,
    this.storeChannel,
    this.failureReason,
  });

  final String status;
  final String? code;
  final String? targetPath;
  final String? storeChannel;
  final String? failureReason;
}
