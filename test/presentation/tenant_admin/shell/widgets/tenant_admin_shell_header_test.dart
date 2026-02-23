import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_admin_shell_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders breadcrumb and triggers back callback', (tester) async {
    var backTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminShellHeader(
            title: 'Preferências',
            breadcrumbs: const <String>['Configurações'],
            showBackButton: true,
            onBack: () => backTapped = true,
            tenantLabel: 'Guarappari',
            canChangeTenant: true,
            onChangeTenant: () {},
            actions: const <Widget>[],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('tenant_admin_shell_header_back')),
        findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Preferências'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('tenant_admin_shell_header_back')));
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  testWidgets('hides back button when disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminShellHeader(
            title: 'Configurações',
            tenantLabel: 'Guarappari',
            canChangeTenant: true,
            onChangeTenant: _noop,
            actions: const <Widget>[],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('tenant_admin_shell_header_back')),
        findsNothing);
  });
}

void _noop() {}
