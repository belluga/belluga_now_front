import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/partners/routes/partner_detail_route.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      'returns plain account profile detail screen when cover is missing',
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

    expect(builtScreen, isA<AccountProfileDetailScreen>());
  });
}
