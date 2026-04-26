import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDataDTO profile type visual registry', () {
    test('parses canonical visual payload into public registry', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: [
            {
              'type': 'venue',
              'label': 'Venue',
              'labels': {'singular': 'Venue', 'plural': 'Venues'},
              'visual': {
                'mode': 'icon',
                'icon': 'place',
                'color': '#FF8800',
                'icon_color': '#101010',
              },
              'capabilities': {'is_favoritable': true, 'is_poi_enabled': true},
            },
          ],
        ),
      ).toDomain(localInfo: _localInfo());

      final definition = appData.profileTypeRegistry.byType(
        ProfileTypeKeyValue('venue'),
      );

      expect(definition, isNotNull);
      expect(definition!.label, 'Venue');
      expect(definition.pluralLabel, 'Venues');
      expect(definition.visual?.mode, ProfileTypeVisualMode.icon);
      expect(definition.visual?.icon, 'place');
      expect(definition.visual?.color, '#FF8800');
      expect(definition.visual?.iconColor, '#101010');
    });

    test('falls back to legacy poi_visual payload in public registry', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: [
            {
              'type': 'artist',
              'label': 'Artist',
              'poi_visual': {'image_source': 'cover'},
              'capabilities': {'has_cover': true},
            },
          ],
        ),
      ).toDomain(localInfo: _localInfo());

      final definition = appData.profileTypeRegistry.byType(
        ProfileTypeKeyValue('artist'),
      );

      expect(definition, isNotNull);
      expect(definition!.visual?.mode, ProfileTypeVisualMode.image);
      expect(
        definition.visual?.imageSource,
        ProfileTypeVisualImageSource.cover,
      );
    });

    test('parses type_asset image visuals with canonical image url', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: [
            {
              'type': 'restaurant',
              'label': 'Restaurant',
              'visual': {
                'mode': 'image',
                'image_source': 'type_asset',
                'image_url':
                    'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
              },
              'type_asset_url':
                  'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
              'capabilities': {'is_poi_enabled': true},
            },
          ],
        ),
      ).toDomain(localInfo: _localInfo());

      final definition = appData.profileTypeRegistry.byType(
        ProfileTypeKeyValue('restaurant'),
      );

      expect(definition, isNotNull);
      expect(definition!.visual?.mode, ProfileTypeVisualMode.image);
      expect(
        definition.visual?.imageSource,
        ProfileTypeVisualImageSource.typeAsset,
      );
      expect(
        definition.visual?.imageUrl,
        'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
      );
    });

    test('normalizes reference location capability in public registry', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: [
            {
              'type': 'hotel',
              'label': 'Hotel',
              'capabilities': {
                'is_poi_enabled': false,
                'is_reference_location_enabled': true,
              },
            },
            {
              'type': 'venue',
              'label': 'Venue',
              'capabilities': {
                'is_poi_enabled': true,
                'is_reference_location_enabled': true,
              },
            },
          ],
        ),
      ).toDomain(localInfo: _localInfo());

      final hotel = appData.profileTypeRegistry.byType(
        ProfileTypeKeyValue('hotel'),
      );
      final venue = appData.profileTypeRegistry.byType(
        ProfileTypeKeyValue('venue'),
      );

      expect(hotel, isNotNull);
      expect(hotel!.capabilities.isReferenceLocationEnabled, isFalse);
      expect(venue, isNotNull);
      expect(venue!.capabilities.isReferenceLocationEnabled, isTrue);
    });
  });
}

Map<String, dynamic> _basePayload({
  required List<Map<String, dynamic>> profileTypes,
}) {
  return {
    'tenant_id': 'tenant-1',
    'name': 'Belluga',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': profileTypes,
    'theme_data_settings': const <String, dynamic>{
      'primary_seed_color': '#4FA0E3',
      'secondary_seed_color': '#E80D5D',
    },
  };
}

AppDataLocalInfoDTO _localInfo() {
  return AppDataLocalInfoDTO.fromLegacyMap({
    'platformType': PlatformTypeValue(defaultValue: AppType.mobile)
      ..parse(AppType.mobile.name),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'device': 'android',
  });
}
