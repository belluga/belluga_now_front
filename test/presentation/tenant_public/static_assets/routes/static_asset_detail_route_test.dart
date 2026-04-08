import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/routes/static_asset_detail_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'wraps static asset detail with image palette theme when cover exists',
    (tester) async {
      final route = StaticAssetDetailRoute(assetRef: 'praia-das-virtudes');
      final asset = PublicStaticAssetModel(
        idValue: PublicStaticAssetIdValue(defaultValue: 'asset-1'),
        profileTypeValue: PublicStaticAssetTypeValue(defaultValue: 'beach'),
        displayNameValue:
            PublicStaticAssetNameValue(defaultValue: 'Praia das Virtudes'),
        slugValue: SlugValue()..parse('praia-das-virtudes'),
        coverValue:
            ThumbUriValue(defaultValue: Uri.parse('https://example.com/praia.png')),
      );

      late Widget builtScreen;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              builtScreen = route.buildScreen(context, asset);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(builtScreen, isA<ImagePaletteTheme>());
    },
  );
}
