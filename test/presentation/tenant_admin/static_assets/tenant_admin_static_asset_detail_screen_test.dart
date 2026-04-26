import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders taxonomy chip with display name instead of slug',
      (tester) async {
    final terms = TenantAdminTaxonomyTerms()
      ..add(
        tenantAdminTaxonomyTermFromRaw(
          type: 'genre',
          value: 'samba',
          name: 'Samba',
          taxonomyName: 'Genero musical',
          label: 'Legacy Samba',
        ),
      );
    final asset = tenantAdminStaticAssetFromRaw(
      id: 'asset-1',
      profileType: 'poi',
      displayName: 'Praia da Serra',
      slug: 'praia-da-serra',
      isActive: true,
      taxonomyTerms: terms,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminStaticAssetDetailScreen(asset: asset),
      ),
    );

    expect(find.widgetWithText(Chip, 'Samba'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'samba'), findsNothing);
    expect(find.widgetWithText(Chip, 'genre:samba'), findsNothing);
  });
}
