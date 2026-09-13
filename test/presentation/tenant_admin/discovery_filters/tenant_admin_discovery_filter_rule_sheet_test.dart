import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_rule_catalog.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/widgets/tenant_admin_discovery_filter_rule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Map entity selection is exclusive', (tester) async {
    await _pumpRuleSheet(tester, TenantAdminDiscoveryFilterQuery());

    await tester.tap(find.widgetWithText(FilterChip, 'Evento'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Conta'));
    await tester.pump();

    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Evento'))
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Conta'))
          .selected,
      isTrue,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('unknown legacy Map entity remains visibly invalid on open', (
    tester,
  ) async {
    await _pumpRuleSheet(
      tester,
      TenantAdminDiscoveryFilterQuery(
        entityValues: <TenantAdminLowercaseTokenValue>[_token('ticketing')],
      ),
    );

    expect(find.textContaining('não é reconhecida'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('foreign type-map key remains visibly invalid on open', (
    tester,
  ) async {
    await _pumpRuleSheet(
      tester,
      TenantAdminDiscoveryFilterQuery(
        entityValues: <TenantAdminLowercaseTokenValue>[_token('event')],
        typeValuesByEntity: <String, List<TenantAdminLowercaseTokenValue>>{
          'account_profile': <TenantAdminLowercaseTokenValue>[
            _token('restaurant'),
          ],
        },
      ),
    );

    expect(find.textContaining('tipos vinculados'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}

Future<void> _pumpRuleSheet(
  WidgetTester tester,
  TenantAdminDiscoveryFilterQuery query,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TenantAdminDiscoveryFilterRuleSheet(
          filter: TenantAdminDiscoveryFilterCatalogItem(
            keyValue: _token('filter'),
            labelValue: TenantAdminRequiredTextValue()..parse('Filtro'),
            query: query,
          ),
          surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
          catalog: const TenantAdminMapFilterRuleCatalog.empty(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TenantAdminLowercaseTokenValue _token(String raw) =>
    TenantAdminLowercaseTokenValue.fromRaw(raw);
