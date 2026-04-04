import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/shared/widgets/seed_palette_theme.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/partners/routes/partner_detail_route.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
      'wraps account profile detail with image palette theme when cover exists',
      (tester) async {
    final route = const PartnerDetailRoute(slug: 'guarapari-vibes');
    final profile = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439011',
      name: 'Guarapari Vibes',
      slug: 'guarapari-vibes',
      type: 'artist',
      coverUrl: 'https://example.com/cover.png',
    );

    late Widget builtScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            builtScreen = route.buildScreen(context, profile);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(builtScreen, isA<ImagePaletteTheme>());
  });

  testWidgets(
      'wraps account profile detail with image palette theme when avatar is the final hero image source',
      (tester) async {
    final route = const PartnerDetailRoute(slug: 'guarapari-vibes');
    final profile = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439011',
      name: 'Guarapari Vibes',
      slug: 'guarapari-vibes',
      type: 'artist',
      avatarUrl: 'https://example.com/avatar.png',
    );

    late Widget builtScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            builtScreen = route.buildScreen(context, profile);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(builtScreen, isA<ImagePaletteTheme>());
  });

  testWidgets(
      'wraps account profile detail with seed palette theme when only type-visual color fallback exists',
      (tester) async {
    final route = const PartnerDetailRoute(slug: 'guarapari-vibes');
    final profile = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439011',
      name: 'Guarapari Vibes',
      slug: 'guarapari-vibes',
      type: 'artist',
    );

    late Widget builtScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            builtScreen = route.buildScreen(context, profile);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(builtScreen, isA<SeedPaletteTheme>());
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
