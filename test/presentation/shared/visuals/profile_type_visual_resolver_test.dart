import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_hex_color_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_icon_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_image_url_value.dart';
import 'package:belluga_now/presentation/shared/visuals/profile_type_visual_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileTypeVisualResolver', () {
    test('resolves icon visuals with canonical colors', () {
      final resolved = ProfileTypeVisualResolver.resolve(
        visual: ProfileTypeVisual.icon(
          iconValue: ProfileTypeVisualIconValue('place'),
          colorValue: ProfileTypeVisualHexColorValue()..parse('#FF8800'),
          iconColorValue: ProfileTypeVisualHexColorValue()..parse('#101010'),
        ),
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: 'https://tenant.test/cover.png',
      );

      expect(resolved, isNotNull);
      expect(resolved!.isIcon, isTrue);
      expect(resolved.iconData, isNotNull);
      expect(resolved.backgroundColor, const Color(0xFFFF8800));
      expect(resolved.iconColor, const Color(0xFF101010));
      expect(resolved.imageUrl, isNull);
    });

    test('resolves image visuals from requested media source', () {
      final resolved = ProfileTypeVisualResolver.resolve(
        visual: ProfileTypeVisual.image(
          imageSource: ProfileTypeVisualImageSource.cover,
        ),
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: 'https://tenant.test/cover.png',
      );

      expect(resolved, isNotNull);
      expect(resolved!.isImage, isTrue);
      expect(resolved.imageUrl, 'https://tenant.test/cover.png');
    });

    test('returns null when image mode requires missing media', () {
      final resolved = ProfileTypeVisualResolver.resolve(
        visual: ProfileTypeVisual.image(
          imageSource: ProfileTypeVisualImageSource.cover,
        ),
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: null,
      );

      expect(resolved, isNull);
    });

    test('resolves type_asset visuals from canonical image url', () {
      final resolved = ProfileTypeVisualResolver.resolve(
        visual: ProfileTypeVisual.image(
          imageSource: ProfileTypeVisualImageSource.typeAsset,
          imageUrlValue: ProfileTypeVisualImageUrlValue(
            'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
          ),
        ),
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: 'https://tenant.test/cover.png',
      );

      expect(resolved, isNotNull);
      expect(resolved!.isImage, isTrue);
      expect(
        resolved.imageUrl,
        'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
      );
    });
  });
}
