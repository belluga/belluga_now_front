import 'dart:math' as math;

import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/infrastructure/dal/decoders/account_profile_external_link_decoder.dart';
import 'package:belluga_now/presentation/tenant_public/partners/widgets/account_profile_external_link_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_icons/simple_icons.dart';

void main() {
  testWidgets('occupies no space when there are no valid links', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileExternalLinkStrip(links: const [], onOpen: (_) {}),
      ),
    );

    expect(
      find.byKey(const Key('accountProfileExternalLinkStrip')),
      findsNothing,
    );
  });

  testWidgets('renders 48px semantic buttons in registry order', (
    tester,
  ) async {
    final opened = <String>[];
    final links = AccountProfileExternalLinkDecoder.decodeList([
      {
        'id': 'website',
        'type': 'website',
        'url': 'https://example.org',
        'label': 'Official site',
      },
      {
        'id': 'instagram',
        'type': 'instagram',
        'url': 'https://instagram.com/profile',
      },
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountProfileExternalLinkStrip(
            links: links,
            onOpen: (link) => opened.add(link.id),
          ),
        ),
      ),
    );

    final instagram = find.byKey(
      const ValueKey('accountProfileExternalLink-instagram'),
    );
    final website = find.byKey(
      const ValueKey('accountProfileExternalLink-website'),
    );
    expect(tester.getSize(instagram), const Size(48, 48));
    expect(
      tester
          .getSize(find.byKey(const Key('accountProfileExternalLinkStrip')))
          .height,
      inInclusiveRange(56, 64),
    );
    final stripMaterial = tester.widget<Material>(
      find.byKey(const Key('accountProfileExternalLinkStrip')),
    );
    expect(
      stripMaterial.color,
      Theme.of(tester.element(instagram)).colorScheme.surface,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('accountProfileExternalLinkStrip')),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    expect(
      tester.getTopLeft(instagram).dx,
      lessThan(tester.getTopLeft(website).dx),
    );
    expect(find.bySemanticsLabel('Abrir Instagram'), findsOneWidget);
    final instagramButton = tester.widget<IconButton>(instagram);
    expect(instagramButton.tooltip, 'Instagram');
    final colorScheme = Theme.of(tester.element(instagram)).colorScheme;
    final background = _materialUnder(tester, instagram).color;
    final foreground = _iconColorUnder(tester, instagram);
    expect(background, colorScheme.secondaryContainer);
    expect(_contrastRatio(background!, foreground), greaterThanOrEqualTo(4.5));
    final instagramIcon = tester.widget<Icon>(
      find.descendant(of: instagram, matching: find.byType(Icon)),
    );
    expect(instagramIcon.icon, SimpleIcons.instagram);

    await tester.tap(instagram);
    expect(opened, ['instagram']);
  });

  testWidgets('routes every supported type through the external-open intent', (
    tester,
  ) async {
    final opened = <AccountProfileExternalLinkType>[];
    final urls = <AccountProfileExternalLinkType, String>{
      AccountProfileExternalLinkType.instagram: 'https://instagram.com/belluga',
      AccountProfileExternalLinkType.facebook: 'https://facebook.com/belluga',
      AccountProfileExternalLinkType.youtube: 'https://youtube.com/@belluga',
      AccountProfileExternalLinkType.tiktok: 'https://tiktok.com/@belluga',
      AccountProfileExternalLinkType.spotify:
          'https://open.spotify.com/artist/belluga',
      AccountProfileExternalLinkType.website: 'https://belluga.example/about',
    };

    for (final type in AccountProfileExternalLinkType.values) {
      final link = AccountProfileExternalLinkRegistry.validateMutation(
        id: AccountProfileExternalLinkIdValue(type.wireValue),
        type: type,
        url: AccountProfileExternalLinkUrlValue(urls[type]!),
        label: type == AccountProfileExternalLinkType.website
            ? AccountProfileExternalLinkLabelValue('Belluga')
            : null,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AccountProfileExternalLinkStrip(
            links: [link],
            onOpen: (selected) => opened.add(selected.type),
          ),
        ),
      );
      await tester.tap(
        find.byKey(ValueKey('accountProfileExternalLink-${type.wireValue}')),
      );
    }

    expect(opened, AccountProfileExternalLinkType.values);
  });

  testWidgets(
    'keeps the derived background and resolves an accessible icon foreground',
    (tester) async {
      final link = AccountProfileExternalLinkRegistry.validateMutation(
        id: AccountProfileExternalLinkIdValue('instagram'),
        type: AccountProfileExternalLinkType.instagram,
        url: AccountProfileExternalLinkUrlValue(
          'https://instagram.com/belluga',
        ),
      );
      final schemes = <ColorScheme>[
        ColorScheme.light().copyWith(
          secondaryContainer: const Color(0xfff5f5f5),
          onSecondaryContainer: const Color(0xfff5f5f5),
        ),
        ColorScheme.dark().copyWith(
          secondaryContainer: const Color(0xff121212),
          onSecondaryContainer: const Color(0xff121212),
        ),
      ];

      for (final scheme in schemes) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('accountContrast-${scheme.brightness}'),
            theme: ThemeData(colorScheme: scheme),
            home: Scaffold(
              body: AccountProfileExternalLinkStrip(
                links: [link],
                onOpen: (_) {},
              ),
            ),
          ),
        );

        final button = find.byKey(
          const ValueKey('accountProfileExternalLink-instagram'),
        );
        final background = _materialUnder(tester, button).color;
        final foreground = _iconColorUnder(tester, button);

        expect(background, scheme.secondaryContainer);
        expect(
          _contrastRatio(background!, foreground),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}

Material _materialUnder(WidgetTester tester, Finder finder) {
  return tester
      .widgetList<Material>(
        find.descendant(of: finder, matching: find.byType(Material)),
      )
      .last;
}

Color _iconColorUnder(WidgetTester tester, Finder finder) {
  final icon = find.descendant(of: finder, matching: find.byType(Icon));
  return IconTheme.of(tester.element(icon)).color!;
}

double _contrastRatio(Color background, Color foreground) {
  final light = math.max(
    background.computeLuminance(),
    foreground.computeLuminance(),
  );
  final dark = math.min(
    background.computeLuminance(),
    foreground.computeLuminance(),
  );
  return (light + 0.05) / (dark + 0.05);
}
