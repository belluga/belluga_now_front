class TenantAdminImageSafeAreaGuideSpec {
  const TenantAdminImageSafeAreaGuideSpec({
    required this.sideInsetFraction,
    required this.topOverlayFraction,
    required this.bottomOverlayFraction,
    required this.topLabel,
    required this.focusLabel,
    required this.bottomLabel,
    required this.helper,
  });

  final double sideInsetFraction;
  final double topOverlayFraction;
  final double bottomOverlayFraction;
  final String topLabel;
  final String focusLabel;
  final String bottomLabel;
  final String helper;
}
