import 'package:belluga_now/domain/partners/account_profile_gallery_item.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountProfileGalleryItem.previewUrl', () {
    test(
      'prefers canonical image before thumb for public compact previews',
      () {
        final item = buildAccountProfileGalleryItemFromPrimitives(
          itemId: 'gallery-item-1',
          description: 'Vista para o palco',
          imageUrl: 'https://example.com/gallery-item-1?variant=image',
          thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
          cardUrl: 'https://example.com/gallery-item-1?variant=card',
          modalUrl: 'https://example.com/gallery-item-1?variant=modal',
        );

        expect(
          item.previewUrl,
          'https://example.com/gallery-item-1?variant=image',
        );
      },
    );

    test('falls back through card, modal, and thumb when needed', () {
      final cardOnly = _buildItem(
        cardUrl: 'https://example.com/gallery-item-1?variant=card',
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
      );
      final modalOnly = _buildItem(
        modalUrl: 'https://example.com/gallery-item-1?variant=modal',
        thumbUrl: 'https://example.com/gallery-item-1?variant=thumb',
      );
      final thumbOnly = _buildItem(
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

AccountProfileGalleryItem _buildItem({
  String? imageUrl,
  String? thumbUrl,
  String? cardUrl,
  String? modalUrl,
}) {
  return AccountProfileGalleryItem(
    itemIdValue: AccountProfileNestedGroupIdValue('gallery-item-1'),
    descriptionValue: AccountProfileNestedGroupMemberTextValue(''),
    orderValue: AccountProfileNestedGroupOrderValue(0),
    imageUrlValue: _buildThumbUriValue(imageUrl),
    thumbUrlValue: _buildThumbUriValue(thumbUrl),
    cardUrlValue: _buildThumbUriValue(cardUrl),
    modalUrlValue: _buildThumbUriValue(modalUrl),
  );
}

ThumbUriValue _buildThumbUriValue(String? url) {
  final value = ThumbUriValue(defaultValue: Uri());
  if (url != null) {
    value.parse(url);
  }
  return value;
}
