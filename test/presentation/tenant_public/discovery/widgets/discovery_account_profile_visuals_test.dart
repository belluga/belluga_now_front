import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_nearby_row.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_card.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_grid.dart';
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
    expect(find.byKey(const Key('discoveryPartnerIdentityAvatar')),
        findsOneWidget);
    expect(find.byKey(const Key('discoveryPartnerTypeAvatar')), findsOneWidget);
    expect(find.byTooltip('Favoritar perfil Ananda Torres'), findsOneWidget);
    expect(find.text('Ananda Torres'), findsOneWidget);
    expect(find.text('brasilidades'), findsOneWidget);
    expect(find.text('samba'), findsOneWidget);
  });

  testWidgets('DiscoveryPartnerCard renders tags over the image bottom',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final partner = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439030',
      name: 'Forró Piseiro Smoke Perfil Público',
      slug: 'forro-piseiro-smoke',
      type: 'artist',
      tags: const ['Forró Pé de Serra', 'Música Ao Vivo', 'Piseiro'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 182,
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

    final imageBottom =
        tester.getBottomRight(find.byType(AspectRatio).first).dy;
    expect(
      tester.getCenter(find.text('Forró Pé de Serra')).dy,
      lessThan(imageBottom),
    );
    expect(
      tester.getCenter(find.text('Música Ao Vivo')).dy,
      lessThan(imageBottom),
    );
    final overlayRect = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryPartnerImageTagsOverlay')),
    );
    final firstTagRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('discoveryPartnerImageTag:Forró Pé de Serra'),
      ),
    );
    final secondTagRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('discoveryPartnerImageTag:Música Ao Vivo'),
      ),
    );
    expect(firstTagRect.left, greaterThanOrEqualTo(overlayRect.left));
    expect(firstTagRect.right, lessThanOrEqualTo(overlayRect.right));
    expect(secondTagRect.left, greaterThanOrEqualTo(overlayRect.left));
    expect(secondTagRect.right, lessThanOrEqualTo(overlayRect.right));
    final visibleTagCenters = <double>[
      tester.getCenter(find.text('Forró Pé de Serra')).dy,
      tester.getCenter(find.text('Música Ao Vivo')).dy,
    ];
    expect(_distinctVerticalRows(visibleTagCenters),
        hasLength(lessThanOrEqualTo(2)));
    expect(
      tester.widget<Text>(find.text('Forró Pé de Serra')).maxLines,
      1,
    );
    expect(
      tester.widget<Text>(find.text('Música Ao Vivo')).maxLines,
      1,
    );
    expect(find.text('Piseiro'), findsNothing);
  });

  testWidgets('DiscoveryPartnerCard accepts multiple tags capped to two rows',
      (tester) async {
    final registry = _buildAppData().profileTypeRegistry;
    final partner = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439033',
      name: 'Casa Musical',
      slug: 'casa-musical',
      type: 'artist',
      tags: const ['Axé', 'Bar', 'DJ', 'Ao Vivo', 'Praia', 'Família'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: DiscoveryPartnerCard(
              partner: partner,
              isFavorite: false,
              isFavoritable: false,
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

    final visibleLabels = <String>[
      'Axé',
      'Bar',
      'DJ',
      'Ao Vivo',
      'Praia',
      'Família',
    ]
        .where((label) => find.text(label).evaluate().isNotEmpty)
        .toList(growable: false);
    expect(visibleLabels.length, greaterThan(2));

    final visibleRows = _distinctVerticalRows(
      visibleLabels
          .map((label) => tester.getCenter(find.text(label)).dy)
          .toList(growable: false),
    );
    expect(visibleRows, hasLength(lessThanOrEqualTo(2)));

    final overlayRect = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryPartnerImageTagsOverlay')),
    );
    for (final label in visibleLabels) {
      final tagRect = tester.getRect(
        find.byKey(ValueKey<String>('discoveryPartnerImageTag:$label')),
      );
      expect(tagRect.left, greaterThanOrEqualTo(overlayRect.left));
      expect(tagRect.right, lessThanOrEqualTo(overlayRect.right));
      expect(tester.widget<Text>(find.text(label)).maxLines, 1);
      expect(tester.widget<Text>(find.text(label)).overflow,
          TextOverflow.ellipsis);
    }
  });

  testWidgets(
      'DiscoveryPartnerGrid keeps tagged account profile cards within mobile cell constraints',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = _buildAppData().profileTypeRegistry;
    final partners = <AccountProfileModel>[
      buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439031',
        name: 'Promotion Smoke Perfil Público',
        slug: 'promotion-smoke-a',
        type: 'restaurant',
        tags: const ['Forró Piseiro Smoke'],
      ),
      buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439032',
        name: 'Promotion Smoke Perfil Público',
        slug: 'promotion-smoke-b',
        type: 'restaurant',
        tags: const ['Forró Piseiro Smoke'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: DiscoveryPartnerGrid(
                  partners: partners,
                  favorites: const <String>{},
                  isFavoritable: (_) => true,
                  onFavoriteTap: (_) {},
                  onPartnerTap: (_) {},
                  resolvedVisualForPartner: (partner) =>
                      AccountProfileVisualResolver.resolve(
                    accountProfile: partner,
                    registry: registry,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
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

  testWidgets('DiscoveryPartnerCard exposes a named semantic favorite button',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final registry = _buildAppData().profileTypeRegistry;
      final partner = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd79943902f',
        name: 'Ananda Torres',
        slug: 'ananda-torres',
        type: 'artist',
      );
      var favoriteTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: DiscoveryPartnerCard(
                partner: partner,
                isFavorite: false,
                isFavoritable: true,
                onFavoriteTap: () => favoriteTapCount += 1,
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

      final favoriteAction =
          find.bySemanticsLabel(RegExp('Favoritar perfil Ananda Torres'));
      expect(favoriteAction, findsOneWidget);

      await tester.tap(favoriteAction);
      await tester.pump();
      expect(favoriteTapCount, 1);
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

    expect(
        find.byKey(const Key('discoveryPartnerIdentityAvatar')), findsNothing);
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
      'DiscoveryPartnerCard removes button semantics when public detail is unavailable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final registry = _buildAppData().profileTypeRegistry;
      final partner = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439028',
        name: 'Perfil Sem Rota',
        slug: 'perfil-sem-rota',
        type: 'artist',
        canOpenPublicDetail: false,
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
                onTap: null,
                resolvedVisual: AccountProfileVisualResolver.resolve(
                  accountProfile: partner,
                  registry: registry,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Abrir perfil Perfil Sem Rota')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(RegExp('Perfil Perfil Sem Rota')),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'DiscoveryNearbyRow removes button semantics when public detail is unavailable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final registry = _buildAppData().profileTypeRegistry;
      final items = <AccountProfileModel>[
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439029',
          name: 'Sem Navegação',
          slug: 'sem-navegacao',
          type: 'artist',
          canOpenPublicDetail: false,
        ),
      ];
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryNearbyRow(
              items: items,
              onTap: (_) => tapped = true,
              resolvedVisualForItem: (item) =>
                  AccountProfileVisualResolver.resolve(
                accountProfile: item,
                registry: registry,
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Abrir perfil Sem Navegação')),
        findsNothing,
      );
      final staticLabel = find.bySemanticsLabel(RegExp('Perfil Sem Navegação'));
      expect(staticLabel, findsOneWidget);

      await tester.tap(find.text('Sem Navegação'));
      await tester.pump();
      expect(tapped, isFalse);
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
            resolvedVisualForItem: (item) =>
                AccountProfileVisualResolver.resolve(
              accountProfile: item,
              registry: registry,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('discoveryNearbyHalo')), findsNothing);
    final avatarImage = tester
        .widgetList<Image>(
          find.byType(Image),
        )
        .where((widget) => widget.image is NetworkImage)
        .toList();
    expect(
      avatarImage.any(
        (widget) =>
            (widget.image as NetworkImage).url ==
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

List<double> _distinctVerticalRows(List<double> centers) {
  final rows = <double>[];
  for (final center in centers) {
    final belongsToExistingRow = rows.any(
      (rowCenter) => (rowCenter - center).abs() < 4,
    );
    if (!belongsToExistingRow) {
      rows.add(center);
    }
  }
  return rows;
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
