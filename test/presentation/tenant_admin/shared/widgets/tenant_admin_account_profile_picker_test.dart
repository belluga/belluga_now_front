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
        displayName:
            'Perfil Elegível com nome suficientemente grande para pressionar o layout em largura curta',
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
                  onSearchChanged: (_) {},
                  profileTypes: const [],
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

      final candidate = find.byKey(
        const Key('tenantAdminAccountProfilePickerCandidate_profile-source'),
      );
      expect(candidate, findsOneWidget);

      await tester.tap(candidate);
      await tester.pumpAndSettle();

      expect(selected, same(source));

      candidates.dispose();
      loading.dispose();
      pageLoading.dispose();
      hasMore.dispose();
      error.dispose();
    },
  );

  testWidgets('renders the controller error when no candidates are available', (
    tester,
  ) async {
    final candidates = StreamValue<List<TenantAdminAccountProfile>>(
      defaultValue: const <TenantAdminAccountProfile>[],
    );
    final loading = StreamValue<bool>(defaultValue: false);
    final pageLoading = StreamValue<bool>(defaultValue: false);
    final hasMore = StreamValue<bool>(defaultValue: false);
    final error = StreamValue<String?>();

    await pumpAutoRouteTestApp(
      tester,
      routeName: 'tenant-admin-account-profile-picker-error-test',
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      child: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showTenantAdminAccountProfilePicker(
                context: context,
                candidatesStreamValue: candidates,
                isLoadingStreamValue: loading,
                isPageLoadingStreamValue: pageLoading,
                hasMoreStreamValue: hasMore,
                errorStreamValue: error,
                onSearchChanged: (_) {},
                profileTypes: const [],
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
    error.addValue('Não foi possível carregar perfis.');
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar perfis.'), findsOneWidget);
    expect(find.text('Nenhum perfil elegível.'), findsNothing);

    candidates.dispose();
    loading.dispose();
    pageLoading.dispose();
    hasMore.dispose();
    error.dispose();
  });

  testWidgets(
    'keeps the picker stable on a short viewport when the keyboard opens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 600);
      addTearDown(tester.view.reset);

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

      await pumpAutoRouteTestApp(
        tester,
        routeName: 'tenant-admin-account-profile-picker-keyboard-test',
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showTenantAdminAccountProfilePicker(
                  context: context,
                  candidatesStreamValue: candidates,
                  isLoadingStreamValue: loading,
                  isPageLoadingStreamValue: pageLoading,
                  hasMoreStreamValue: hasMore,
                  errorStreamValue: error,
                  onSearchChanged: (_) {},
                  profileTypes: const [],
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

      final searchField = find.byKey(
        const Key('tenantAdminAccountProfilePickerSearchField'),
      );
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(searchField, findsOneWidget);
      expect(find.text('Perfil Elegível'), findsOneWidget);
      expect(tester.takeException(), isNull);

      candidates.dispose();
      loading.dispose();
      pageLoading.dispose();
      hasMore.dispose();
      error.dispose();
    },
  );

  testWidgets(
    'keeps the picker stable when it opens with the keyboard already visible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);
      addTearDown(tester.view.resetViewInsets);

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

      await pumpAutoRouteTestApp(
        tester,
        routeName: 'tenant-admin-account-profile-picker-open-keyboard-test',
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showTenantAdminAccountProfilePicker(
                  context: context,
                  candidatesStreamValue: candidates,
                  isLoadingStreamValue: loading,
                  isPageLoadingStreamValue: pageLoading,
                  hasMoreStreamValue: hasMore,
                  errorStreamValue: error,
                  onSearchChanged: (_) {},
                  profileTypes: const [],
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final sheetRect = tester.getRect(
        find.byKey(const Key('tenantAdminAccountProfilePickerSheet')),
      );
      final titleTop = tester.getTopLeft(find.text('Perfil de origem')).dy;
      final availableHeight = 640 - 280 - 32;

      expect(
        find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
        findsOneWidget,
      );
      expect(find.text('Perfil Elegível'), findsOneWidget);
      expect(sheetRect.height, lessThanOrEqualTo(availableHeight.toDouble()));
      expect(titleTop, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);

      candidates.dispose();
      loading.dispose();
      pageLoading.dispose();
      hasMore.dispose();
      error.dispose();
    },
  );

  testWidgets(
    'keeps the multi picker stable when it opens with the keyboard already visible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);
      addTearDown(tester.view.resetViewInsets);

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

      await pumpAutoRouteTestApp(
        tester,
        routeName:
            'tenant-admin-account-profile-multi-picker-open-keyboard-test',
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showTenantAdminAccountProfileMultiPicker(
                    context: context,
                    candidatesStreamValue: candidates,
                    isLoadingStreamValue: loading,
                    isPageLoadingStreamValue: pageLoading,
                    hasMoreStreamValue: hasMore,
                    errorStreamValue: error,
                    onSearchChanged: (_) {},
                    profileTypes: const [],
                    loadNextPage: () async {},
                    title: 'Adicionar perfis',
                    emptyMessage: 'Nenhum perfil elegível.',
                    selectedProfileIds: const <String>{},
                    onSelectionChanged: (_, _) {},
                    doneLabel: 'Adicionar',
                  );
                },
                child: const Text('Abrir multi seletor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir multi seletor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
        findsOneWidget,
      );
      expect(find.text('0 selecionado(s)'), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);
      expect(
        find.byKey(
          const Key('tenantAdminAccountProfilePickerCandidate_profile-source'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      candidates.dispose();
      loading.dispose();
      pageLoading.dispose();
      hasMore.dispose();
      error.dispose();
    },
  );
}
