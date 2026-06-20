import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TenantAdminAccountProfileGalleryItemDraft.previewUrl', () {
    test('prefers canonical image before thumb for admin edit previews', () {
      const draft = TenantAdminAccountProfileGalleryItemDraft(
        itemId: 'gallery-item-1',
        order: 0,
        imageUrl: 'https://example.com/gallery-item-1?variant=modal',
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
        cardUrl: 'https://example.com/gallery-item-1?variant=card',
        modalUrl: 'https://example.com/gallery-item-1?variant=modal',
      );

      expect(
        draft.previewUrl,
        'https://example.com/gallery-item-1?variant=modal',
      );
    });

    test('falls back through card, modal, and thumb when needed', () {
      const cardOnly = TenantAdminAccountProfileGalleryItemDraft(
        itemId: 'gallery-item-1',
        order: 0,
        cardUrl: 'https://example.com/gallery-item-1?variant=card',
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
      );
      const modalOnly = TenantAdminAccountProfileGalleryItemDraft(
        itemId: 'gallery-item-1',
        order: 0,
        modalUrl: 'https://example.com/gallery-item-1?variant=modal',
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
      );
      const thumbOnly = TenantAdminAccountProfileGalleryItemDraft(
        itemId: 'gallery-item-1',
        order: 0,
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
      );

      expect(
        cardOnly.previewUrl,
        'https://example.com/gallery-item-1?variant=card',
      );
      expect(
        modalOnly.previewUrl,
        'https://example.com/gallery-item-1?variant=modal',
      );
      expect(
        thumbOnly.previewUrl,
        'https://example.com/gallery-item-1?variant=thumb',
      );
    });
  });
}
