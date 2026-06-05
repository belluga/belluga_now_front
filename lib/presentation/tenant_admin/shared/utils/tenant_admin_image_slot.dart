export 'tenant_admin_image_safe_area_guide_spec.dart';
export 'tenant_admin_image_slot_spec.dart';

import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_safe_area_guide_spec.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_public_web_image_spec.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_slot_spec.dart';

enum TenantAdminImageSlot {
  avatar,
  cover,
  eventHeroCover,
  accountProfileHeroCover,
  lightLogo,
  darkLogo,
  lightIcon,
  darkIcon,
  pwaIcon,
  publicWebDefaultImage,
  mapFilter,
  typeVisual,
}

TenantAdminImageSlotSpec tenantAdminImageSlotSpecFor(
  TenantAdminImageSlot slot,
) {
  return switch (slot) {
    TenantAdminImageSlot.avatar => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/jpeg',
        fileExtension: 'jpg',
        cropTitle: 'Recortar avatar',
        circularCrop: true,
      ),
    TenantAdminImageSlot.cover => const TenantAdminImageSlotSpec(
        aspectRatio: 560 / 512,
        maxWidth: 1920,
        maxHeight: 1080,
        mimeType: 'image/jpeg',
        fileExtension: 'jpg',
        cropTitle: 'Recortar capa',
      ),
    TenantAdminImageSlot.eventHeroCover => const TenantAdminImageSlotSpec(
        aspectRatio: 5 / 7,
        maxWidth: 1800,
        maxHeight: 2520,
        mimeType: 'image/jpeg',
        fileExtension: 'jpg',
        cropTitle: 'Recortar capa do evento',
        safeAreaGuide: TenantAdminImageSafeAreaGuideSpec(
          sideInsetFraction: 0.08,
          topOverlayFraction: 0.14,
          bottomOverlayFraction: 0.34,
          topLabel: 'Controles',
          focusLabel: 'Foco principal',
          bottomLabel: 'Texto e botoes',
          helper: 'Preencha o recorte mantendo o assunto principal no centro.',
        ),
      ),
    TenantAdminImageSlot.accountProfileHeroCover =>
      const TenantAdminImageSlotSpec(
        aspectRatio: 15 / 16,
        maxWidth: 1800,
        maxHeight: 1920,
        mimeType: 'image/jpeg',
        fileExtension: 'jpg',
        cropTitle: 'Recortar capa do perfil',
        safeAreaGuide: TenantAdminImageSafeAreaGuideSpec(
          sideInsetFraction: 0.08,
          topOverlayFraction: 0.14,
          bottomOverlayFraction: 0.30,
          topLabel: 'Controles',
          focusLabel: 'Foco principal',
          bottomLabel: 'Nome e acoes',
          helper: 'Evite rostos, textos e marcas nas faixas de interface.',
        ),
      ),
    TenantAdminImageSlot.lightLogo => const TenantAdminImageSlotSpec(
        aspectRatio: 18 / 5,
        maxWidth: 1800,
        maxHeight: 500,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar logo claro',
      ),
    TenantAdminImageSlot.darkLogo => const TenantAdminImageSlotSpec(
        aspectRatio: 18 / 5,
        maxWidth: 1800,
        maxHeight: 500,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar logo escuro',
      ),
    TenantAdminImageSlot.lightIcon => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar icone claro',
      ),
    TenantAdminImageSlot.darkIcon => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar icone escuro',
      ),
    TenantAdminImageSlot.pwaIcon => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar icone PWA',
      ),
    TenantAdminImageSlot.mapFilter => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar imagem do filtro',
      ),
    TenantAdminImageSlot.typeVisual => const TenantAdminImageSlotSpec(
        aspectRatio: 1.0,
        maxWidth: 1024,
        maxHeight: 1024,
        mimeType: 'image/png',
        fileExtension: 'png',
        cropTitle: 'Recortar imagem canônica do tipo',
      ),
    TenantAdminImageSlot.publicWebDefaultImage =>
      const TenantAdminImageSlotSpec(
        aspectRatio: tenantAdminPublicWebDefaultImageAspectRatio,
        maxWidth: tenantAdminPublicWebDefaultImageWidth,
        maxHeight: tenantAdminPublicWebDefaultImageHeight,
        mimeType: 'image/jpeg',
        fileExtension: 'jpg',
        cropTitle: 'Recortar imagem de compartilhamento',
      ),
  };
}
