import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGolden(
    WidgetTester tester, {
    required Widget child,
    Size surfaceSize = const Size(430, 932),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden - tenant admin list state', (tester) async {
    await pumpGolden(
      tester,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Taxonomias cadastradas'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: const [
                    Card(
                      child: ListTile(
                        title: Text('Genero'),
                        subtitle: Text('account_profile'),
                        trailing: Icon(Icons.more_vert),
                      ),
                    ),
                    SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        title: Text('Cozinha'),
                        subtitle: Text('static_asset'),
                        trailing: Icon(Icons.more_vert),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Criar taxonomia'),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        'goldens/tenant_admin_list_state.png',
      ),
    );
  });

  testWidgets('golden - tenant admin empty state', (tester) async {
    await pumpGolden(
      tester,
      child: const Scaffold(
        body: TenantAdminEmptyState(
          icon: Icons.account_tree_outlined,
          title: 'Nenhuma taxonomia cadastrada',
          description: 'Use "Criar taxonomia" para organizar termos.',
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        'goldens/tenant_admin_empty_state.png',
      ),
    );
  });

  testWidgets('golden - tenant admin error state', (tester) async {
    await pumpGolden(
      tester,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TenantAdminErrorBanner(
            rawError: 'DioException: 500',
            fallbackMessage: 'Nao foi possivel carregar os dados.',
            onRetry: () {},
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        'goldens/tenant_admin_error_state.png',
      ),
    );
  });

  testWidgets('golden - tenant admin create form state', (tester) async {
    await pumpGolden(
      tester,
      child: TenantAdminFormScaffold(
        title: 'Criar taxonomia',
        child: SingleChildScrollView(
          child: Column(
            children: [
              TenantAdminFormSectionCard(
                title: 'Identidade da taxonomia',
                description:
                    'Defina slug, nome e metadados visuais da taxonomia.',
                child: Column(
                  children: const [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Slug',
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nome',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TenantAdminPrimaryFormAction(
                label: 'Criar taxonomia',
                icon: Icons.add,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        'goldens/tenant_admin_form_state.png',
      ),
    );
  });
}
