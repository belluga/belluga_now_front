import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_safe_area_guide_spec.dart';

class TenantAdminImageSlotSpec {
  const TenantAdminImageSlotSpec({
    required this.aspectRatio,
    required this.maxWidth,
    required this.maxHeight,
    required this.mimeType,
    required this.fileExtension,
    required this.cropTitle,
    this.circularCrop = false,
    this.safeAreaGuide,
  });

  final double? aspectRatio;
  final int maxWidth;
  final int maxHeight;
  final String mimeType;
  final String fileExtension;
  final String cropTitle;
  final bool circularCrop;
  final TenantAdminImageSafeAreaGuideSpec? safeAreaGuide;

  bool get hasSafeAreaGuide => safeAreaGuide != null;
}
