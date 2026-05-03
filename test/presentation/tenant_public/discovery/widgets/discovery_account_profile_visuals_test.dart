import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_nearby_row.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_card.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'DiscoveryPartnerCard removes the textual eyebrow and reuses the shared identity layout',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final partner = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439021',
      name: 'Ananda Torres',
      slug: 'ananda-torres',
      type: 'artist',
      avatarUrl: 'https://tenant.test/avatar.png',
      coverUrl: 'https://tenant.test/cover.png',
      tags: const ['brasilidades', 'samba'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DiscoveryPartnerCard(
              partner: partner,
              isFavorite: false,
              isFavoritable: true,
              onFavoriteTap: () {},
              onTap: () {},
              resolvedVisual: AccountProfileVisualResolver.resolve(
                accountProfile: partner,
                registry: registry,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ARTIST'), findsNothing);
    expect(find.text('Artista'), findsNothing);
    expect(find.byKey(const Key('discoveryPartnerIdentityAvatar')), findsOneWidget);
    expect(find.byKey(const Key('discoveryPartnerTypeAvatar')), findsOneWidget);
    expect(find.text('Ananda Torres'), findsOneWidget);
    expect(find.text('brasilidades'), findsOneWidget);
    expect(find.text('samba'), findsOneWidget);
  });

  testWidgets('DiscoveryPartnerCard exposes a named semantic navigation button',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final registry = _buildAppData().profileTypeRegistry;
      final partner = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439026',
        name: 'Ananda Torres',
        slug: 'ananda-torres',
        type: 'artist',
      );
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: DiscoveryPartnerCard(
                partner: partner,
                isFavorite: false,
                isFavoritable: true,
                onFavoriteTap: () {},
                onTap: () => tapCount += 1,
                resolvedVisual: AccountProfileVisualResolver.resolve(
                  accountProfile: partner,
                  registry: registry,
                ),
              ),
            ),
          ),
        ),
      );

      final action =
          find.bySemanticsLabel(RegExp('Abrir perfil Ananda Torres'));
      expect(action, findsOneWidget);

      await tester.tap(action);
      expect(tapCount, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'DiscoveryPartnerCard uses type visuals as fallback avatar when no avatar exists even if cover exists',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final partner = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439022',
      name: 'Casa Marracini',
      slug: 'casa-marracini',
      type: 'restaurant',
      coverUrl: 'https://tenant.test/cover.png',
      tags: const ['italiano'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DiscoveryPartnerCard(
              partner: partner,
              isFavorite: false,
              isFavoritable: true,
              onFavoriteTap: () {},
              onTap: () {},
              resolvedVisual: AccountProfileVisualResolver.resolve(
                accountProfile: partner,
                registry: registry,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('discoveryPartnerIdentityAvatar')), findsNothing);
    expect(find.byKey(const Key('discoveryPartnerTypeAvatar')), findsOneWidget);
  });

  testWidgets(
      'DiscoveryPartnerCard uses type visuals instead of storefront fallback when no image exists',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final partner = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439023',
      name: 'Ananda Torres',
      slug: 'ananda-torres',
      type: 'artist',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DiscoveryPartnerCard(
              partner: partner,
              isFavorite: false,
              isFavoritable: true,
              onFavoriteTap: () {},
              onTap: () {},
              resolvedVisual: AccountProfileVisualResolver.resolve(
                accountProfile: partner,
                registry: registry,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.storefront), findsNothing);
    expect(
      find.byIcon(MapMarkerVisualResolver.resolveIcon('music_note')),
      findsWidgets,
    );
  });

  testWidgets('DiscoveryNearbyRow exposes named semantic navigation buttons',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final registry = _buildAppData().profileTypeRegistry;
      final items = <AccountProfileModel>[
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439027',
          name: 'Com Avatar',
          slug: 'com-avatar',
          type: 'artist',
        ),
      ];
      var tappedSlug = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryNearbyRow(
              items: items,
              onTap: (item) => tappedSlug = item.slug,
              resolvedVisualForItem: (item) =>
                  AccountProfileVisualResolver.resolve(
                accountProfile: item,
                registry: registry,
              ),
            ),
          ),
        ),
      );

      final action = find.bySemanticsLabel(RegExp('Abrir perfil Com Avatar'));
      expect(action, findsOneWidget);

      await tester.tap(action);
      expect(tappedSlug, 'com-avatar');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'DiscoveryNearbyRow uses compact precedence and type visuals without halo',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final items = <AccountProfileModel>[
      buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439024',
        name: 'Com Avatar',
        slug: 'com-avatar',
        type: 'artist',
        avatarUrl: 'https://tenant.test/avatar.png',
        coverUrl: 'https://tenant.test/cover.png',
        distanceMeters: 397,
      ),
      buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439025',
        name: 'Sem Imagem',
        slug: 'sem-imagem',
        type: 'artist',
        distanceMeters: 550,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryNearbyRow(
            items: items,
            onTap: (_) {},
            resolvedVisualForItem: (item) => AccountProfileVisualResolver.resolve(
              accountProfile: item,
              registry: registry,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('discoveryNearbyHalo')), findsNothing);
    final avatarImage = tester.widgetList<Image>(
      find.byType(Image),
    ).where((widget) => widget.image is NetworkImage).toList();
    expect(
      avatarImage.any(
        (widget) => (widget.image as NetworkImage).url ==
            'https://tenant.test/avatar.png',
      ),
      isTrue,
    );
    expect(find.byIcon(Icons.storefront), findsNothing);
    expect(
      find.byIcon(MapMarkerVisualResolver.resolveIcon('music_note')),
      findsWidgets,
    );
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
        },
      },
      {
        'type': 'restaurant',
        'label': 'Restaurante',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#EF4444',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
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
