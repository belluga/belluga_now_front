import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

import '../../../../support/auto_route_test_harness.dart';

void main() {
  testWidgets(
    'renders server-provided candidates and returns the selected profile',
    (tester) async {
      final source = tenantAdminAccountProfileFromRaw(
        id: 'profile-source',
        accountId: 'account-source',
        profileType: 'venue',
        displayName: 'Perfil Elegível',
        slug: 'perfil-elegivel',
      );
      final candidates = StreamValue<List<TenantAdminAccountProfile>>(
        defaultValue: [source],
      );
      final loading = StreamValue<bool>(defaultValue: false);
      final pageLoading = StreamValue<bool>(defaultValue: false);
      final hasMore = StreamValue<bool>(defaultValue: false);
      final error = StreamValue<String?>();
      TenantAdminAccountProfile? selected;

      await pumpAutoRouteTestApp(
        tester,
        routeName: 'tenant-admin-account-profile-picker-test',
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await showTenantAdminAccountProfilePicker(
                  context: context,
                  candidatesStreamValue: candidates,
                  isLoadingStreamValue: loading,
                  isPageLoadingStreamValue: pageLoading,
                  hasMoreStreamValue: hasMore,
                  errorStreamValue: error,
                  loadNextPage: () async {},
                  title: 'Perfil de origem',
                  emptyMessage: 'Nenhum perfil elegível.',
                );
              },
              child: const Text('Abrir seletor'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir seletor'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil Elegível'), findsOneWidget);
      expect(find.text('perfil-elegivel'), findsOneWidget);

      await tester.tap(find.text('Perfil Elegível'));
      await tester.pumpAndSettle();

      expect(selected, same(source));

      candidates.dispose();
      loading.dispose();
      pageLoading.dispose();
      hasMore.dispose();
      error.dispose();
    },
  );
}
