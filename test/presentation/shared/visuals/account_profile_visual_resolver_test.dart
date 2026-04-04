import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountProfileVisualResolver', () {
    test('uses cover first for surface media and avatar first for compact media', () {
      final appData = _buildAppData();
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Casa Mangue',
        slug: 'casa-mangue',
        type: 'venue',
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: 'https://tenant.test/cover.png',
      );

      final resolved = AccountProfileVisualResolver.resolve(
        accountProfile: profile,
        registry: appData.profileTypeRegistry,
      );

      expect(resolved.typeLabel, 'Venue');
      expect(resolved.surfaceImageUrl, 'https://tenant.test/cover.png');
      expect(resolved.compactImageUrl, 'https://tenant.test/avatar.png');
      expect(resolved.identityAvatarUrl, 'https://tenant.test/avatar.png');
    });

    test('omits identity avatar when only cover exists', () {
      final appData = _buildAppData();
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439012',
        name: 'Casa Mangue',
        slug: 'casa-mangue',
        type: 'venue',
        coverUrl: 'https://tenant.test/cover.png',
      );

      final resolved = AccountProfileVisualResolver.resolve(
        accountProfile: profile,
        registry: appData.profileTypeRegistry,
      );

      expect(resolved.surfaceImageUrl, 'https://tenant.test/cover.png');
      expect(resolved.compactImageUrl, 'https://tenant.test/cover.png');
      expect(resolved.identityAvatarUrl, isNull);
    });

    test('falls back to type-visual image when no avatar or cover exist', () {
      final appData = _buildAppData();
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439013',
        name: 'Casa Mangue',
        slug: 'casa-mangue',
        type: 'venue',
      );

      final resolved = AccountProfileVisualResolver.resolve(
        accountProfile: profile,
        registry: appData.profileTypeRegistry,
      );

      expect(
        resolved.surfaceImageUrl,
        'https://tenant.test/type-asset.png',
      );
      expect(
        resolved.compactImageUrl,
        'https://tenant.test/type-asset.png',
      );
      expect(resolved.identityAvatarUrl, isNull);
      expect(resolved.themeSeedColor, isNull);
    });

    test('uses type-visual color as theme seed when no image-backed source exists',
        () {
      final appData = _buildAppData();
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439014',
        name: 'Ananda Torres',
        slug: 'ananda-torres',
        type: 'artist',
      );

      final resolved = AccountProfileVisualResolver.resolve(
        accountProfile: profile,
        registry: appData.profileTypeRegistry,
      );

      expect(resolved.typeLabel, 'Artista');
      expect(resolved.surfaceImageUrl, isNull);
      expect(resolved.compactImageUrl, isNull);
      expect(resolved.identityAvatarUrl, isNull);
      expect(resolved.typeVisual, isNotNull);
      expect(resolved.themeSeedColor, const Color(0xFF7E22CE));
    });
  });
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artista',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'icon',
          'icon': 'music_note',
          'color': '#7E22CE',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
          'has_events': true,
          'has_bio': true,
        },
      },
      {
        'type': 'venue',
        'label': 'Venue',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'image',
          'image_source': 'type_asset',
          'image_url': 'https://tenant.test/type-asset.png',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
          'has_events': true,
          'has_bio': true,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#7E22CE',
    },
    'main_color': '#7E22CE',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': 'mobile',
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}
