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
                'color': '#00897B',
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
      expect(definition.visual?.color, '#00897B');
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

  group('AppDataDTO publication settings', () {
    test('parses active store targets from app_links settings', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: const [],
          settings: const {
            'app_links': {
              'android': {
                'enabled': true,
                'store_url':
                    'https://play.google.com/store/apps/details?id=app',
              },
              'ios': {
                'enabled': false,
                'store_url': 'https://apps.apple.com/br/app/id123',
              },
            },
          },
        ),
      ).toDomain(localInfo: _localInfo());

      expect(appData.publicationSettings.hasExplicitConfig, isTrue);
      expect(appData.publicationSettings.android.isPublished, isTrue);
      expect(appData.publicationSettings.ios.isPublished, isFalse);
      expect(
        appData.publicationSettings.android.storeUrl,
        'https://play.google.com/store/apps/details?id=app',
      );
    });
  });

  group('AppDataDTO OTP delivery flags', () {
    test('enables SMS fallback from public tenant auth flag only', () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: const [],
          settings: const {
            'tenant_public_auth': {
              'phone_otp': {
                'sms_fallback_enabled': true,
              },
            },
          },
        ),
      ).toDomain(localInfo: _localInfo());

      expect(appData.phoneOtpSmsFallbackEnabled, isTrue);
    });

    test('does not infer SMS fallback from webhook URLs in public app data',
        () {
      final appData = AppDataDTO.fromJson(
        _basePayload(
          profileTypes: const [],
          settings: const {
            'outbound_integrations': {
              'otp': {
                'webhook_url': 'https://integrations.example/sms',
              },
            },
          },
        ),
      ).toDomain(localInfo: _localInfo());

      expect(appData.phoneOtpSmsFallbackEnabled, isFalse);
    });
  });
}

Map<String, dynamic> _basePayload({
  required List<Map<String, dynamic>> profileTypes,
  Map<String, dynamic>? settings,
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
    if (settings != null) 'settings': settings,
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
