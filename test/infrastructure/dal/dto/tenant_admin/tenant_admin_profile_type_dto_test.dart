import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_profile_type_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tenant admin profile type visual parsing', () {
    test('parses canonical visual payload for account profile types', () {
      final dto = TenantAdminProfileTypeDTO.fromJson({
        'type': 'restaurant',
        'label': 'Restaurant',
        'allowed_taxonomies': const ['cuisine'],
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#EB2528',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      });

      final definition = dto.toDomain();

      expect(definition.visual?.mode, TenantAdminPoiVisualMode.icon);
      expect(definition.visual?.icon, 'restaurant');
      expect(definition.visual?.color, '#EB2528');
      expect(definition.visual?.iconColor, '#FFFFFF');
    });

    test('falls back to legacy poi_visual for account profile types', () {
      final dto = TenantAdminProfileTypeDTO.fromJson({
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': const [],
        'poi_visual': {
          'image_source': 'avatar',
        },
        'capabilities': {
          'has_avatar': true,
        },
      });

      final definition = dto.toDomain();

      expect(definition.visual?.mode, TenantAdminPoiVisualMode.image);
      expect(
        definition.visual?.imageSource,
        TenantAdminPoiVisualImageSource.avatar,
      );
    });

    test('parses canonical visual payload for static profile types', () {
      final dto = TenantAdminStaticProfileTypeDTO.fromJson({
        'type': 'beach',
        'label': 'Beach',
        'allowed_taxonomies': const ['region'],
        'visual': {
          'mode': 'image',
          'image_source': 'cover',
        },
        'capabilities': {
          'is_poi_enabled': true,
          'has_cover': true,
        },
      });

      final definition = dto.toDomain();

      expect(definition.visual?.mode, TenantAdminPoiVisualMode.image);
      expect(
        definition.visual?.imageSource,
        TenantAdminPoiVisualImageSource.cover,
      );
    });

    test('parses canonical type_asset image payload for account profile types',
        () {
      final dto = TenantAdminProfileTypeDTO.fromJson({
        'type': 'restaurant',
        'label': 'Restaurant',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'image',
          'image_source': 'type_asset',
          'image_url':
              'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
        },
        'type_asset_url':
            'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
        'capabilities': {
          'is_poi_enabled': true,
        },
      });

      final definition = dto.toDomain();

      expect(definition.visual?.mode, TenantAdminPoiVisualMode.image);
      expect(
        definition.visual?.imageSource,
        TenantAdminPoiVisualImageSource.typeAsset,
      );
      expect(
        definition.visual?.imageUrl,
        'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
      );
    });
  });
}
