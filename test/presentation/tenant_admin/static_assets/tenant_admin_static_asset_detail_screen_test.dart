import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders persisted avatar and cover images', (tester) async {
    const avatarUrl = 'https://tenant-a.test/media/static-assets/avatar.png';
    const coverUrl = 'https://tenant-a.test/media/static-assets/cover.png';

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminStaticAssetDetailScreen(
          asset: const TenantAdminStaticAsset(
            id: 'asset-1',
            profileType: 'beach',
            displayName: 'Praia do Morro',
            slug: 'praia-do-morro',
            isActive: true,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
          ),
        ),
      ),
    );

    final coverImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage &&
          widget.url == coverUrl &&
          widget.height == 160;
    });
    final avatarImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage &&
          widget.url == avatarUrl &&
          widget.width == 72 &&
          widget.height == 72;
    });

    expect(coverImageFinder, findsOneWidget);
    expect(avatarImageFinder, findsOneWidget);
  });
}
