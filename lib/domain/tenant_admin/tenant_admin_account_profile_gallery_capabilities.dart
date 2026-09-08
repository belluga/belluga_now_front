import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

enum TenantAdminGalleryCapacityState { available, atLimit, overLimit }

final class TenantAdminAccountProfileGalleryCapabilities {
  TenantAdminAccountProfileGalleryCapabilities({
    required this.maxGalleriesValue,
    required this.maxItemsPerGalleryValue,
  });

  TenantAdminAccountProfileGalleryCapabilities.empty()
    : maxGalleriesValue = TenantAdminCountValue(),
      maxItemsPerGalleryValue = TenantAdminCountValue();

  final TenantAdminCountValue maxGalleriesValue;
  final TenantAdminCountValue maxItemsPerGalleryValue;

  int get maxGalleries => maxGalleriesValue.value;
  int get maxItemsPerGallery => maxItemsPerGalleryValue.value;
}
