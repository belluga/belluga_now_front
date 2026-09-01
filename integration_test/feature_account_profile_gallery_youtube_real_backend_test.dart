import 'dart:developer' as developer;

import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:dio/dio.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'seed_vm_golden_stream',
    const <String, Object>{},
    stream: 'integration_test.VmServiceProxyGoldenFileComparator',
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: '',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: '',
  );

  testWidgets(
    'real backend granular gallery CRUD and Android mixed viewer lifecycle',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final expectedTenantHost = _normalizeHost(tenantDomainDefine);
      final landlordOrigin = _deriveLandlordOriginFromTenantHost(
        expectedTenantHost,
      );
      final authRepository = LandlordAuthRepository(
        dio: Dio(BaseOptions(baseUrl: '$landlordOrigin/admin/api')),
      );
      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);
      final tenantScope = TenantAdminSelectedTenantRepository();
      final tenantsRepository = LandlordTenantsRepository(
        landlordAuthRepository: authRepository,
        landlordOriginOverride: landlordOrigin,
      );
      final accountsRepository = TenantAdminAccountsRepository(
        tenantScope: tenantScope,
      );
      final profilesRepository = TenantAdminAccountProfilesRepository(
        tenantScope: tenantScope,
      );

      String? accountSlug;
      String? profileType;

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(
          landlordAuthRepoString(
            _requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine),
          ),
          landlordAuthRepoString(
            _requireDefine('LANDLORD_ADMIN_PASSWORD', adminPasswordDefine),
          ),
        );
        expect(authRepository.hasValidSession, isTrue);

        final tenants = await tenantsRepository.fetchTenants();
        final tenant = _resolveTenantByDomain(tenants, expectedTenantHost);
        tenantScope
          ..setAvailableTenants(tenants)
          ..selectTenant(tenant);

        final unique = DateTime.now().microsecondsSinceEpoch.toString();
        final createdType = await profilesRepository.createProfileType(
          type: tenantAdminAccountProfilesRepoString(
            'gallery-runtime-$unique',
            isRequired: true,
          ),
          label: tenantAdminAccountProfilesRepoString(
            'Gallery Runtime $unique',
            isRequired: true,
          ),
          pluralLabel: tenantAdminAccountProfilesRepoString(
            'Gallery Runtime $unique',
          ),
          capabilities: TenantAdminProfileTypeCapabilities(
            isQueryable: TenantAdminFlagValue(true),
            isPubliclyNavigable: TenantAdminFlagValue(true),
            isPubliclyDiscoverable: TenantAdminFlagValue(true),
            isFavoritable: TenantAdminFlagValue(false),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
            hasGallery: TenantAdminFlagValue(true),
          ),
        );
        profileType = createdType.type;

        final onboarding = await accountsRepository.createAccountOnboarding(
          name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            'Gallery Runtime $unique',
            isRequired: true,
          ),
          ownershipState: TenantAdminOwnershipState.unmanaged,
          profileType: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            createdType.type,
            isRequired: true,
          ),
        );
        accountSlug = onboarding.account.slug;
        final profileId = tenantAdminAccountProfilesRepoString(
          onboarding.accountProfile.id,
          isRequired: true,
        );
        var snapshot = await profilesRepository.createGalleryGroup(
          accountProfileId: profileId,
          subtitle: tenantAdminAccountProfilesRepoString(
            'Primeira',
            isRequired: true,
          ),
        );
        expect(snapshot.groups, hasLength(1));
        expect(snapshot.groups.single.items, isEmpty);
        expect(snapshot.capabilities.maxGalleries, greaterThan(0));
        expect(snapshot.capabilities.maxItemsPerGallery, greaterThan(0));
        final firstGroupId = snapshot.groups.single.groupId;
        var persistedProfile = await profilesRepository.fetchAccountProfile(
          profileId,
        );
        expect(persistedProfile.galleryGroups, hasLength(1));
        expect(persistedProfile.galleryGroups.single.groupId, firstGroupId);
        expect(persistedProfile.galleryGroups.single.items, isEmpty);

        snapshot = await profilesRepository.createGalleryGroup(
          accountProfileId: profileId,
          subtitle: tenantAdminAccountProfilesRepoString(
            'Segunda',
            isRequired: true,
          ),
        );
        final secondGroupId = snapshot.groups.last.groupId;

        snapshot = await profilesRepository.renameGalleryGroup(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            firstGroupId,
            isRequired: true,
          ),
          subtitle: tenantAdminAccountProfilesRepoString(
            'Primeira renomeada',
            isRequired: true,
          ),
        );
        expect(snapshot.groups.first.subtitle, 'Primeira renomeada');

        snapshot = await profilesRepository.reorderGalleryGroups(
          accountProfileId: profileId,
          groupIds: [
            tenantAdminAccountProfilesRepoString(
              secondGroupId,
              isRequired: true,
            ),
            tenantAdminAccountProfilesRepoString(
              firstGroupId,
              isRequired: true,
            ),
          ],
        );
        expect(snapshot.groups.map((group) => group.groupId), [
          secondGroupId,
          firstGroupId,
        ]);

        snapshot = await profilesRepository.createGalleryItem(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            secondGroupId,
            isRequired: true,
          ),
          type: TenantAdminAccountProfileGalleryItemType.youtube,
          description: TenantAdminOptionalTextValue()..parse('Vídeo principal'),
          youtubeUrl: tenantAdminAccountProfilesRepoString(
            'https://youtu.be/dQw4w9WgXcQ',
            isRequired: true,
          ),
        );
        final firstItemId = snapshot.groups.first.items.single.itemId;

        snapshot = await profilesRepository.createGalleryItem(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            secondGroupId,
            isRequired: true,
          ),
          type: TenantAdminAccountProfileGalleryItemType.youtube,
          description: TenantAdminOptionalTextValue()..parse('Vídeo auxiliar'),
          youtubeUrl: tenantAdminAccountProfilesRepoString(
            'https://youtu.be/M7lc1UVf-VE',
            isRequired: true,
          ),
        );
        final secondItemId = snapshot.groups.first.items.last.itemId;

        snapshot = await profilesRepository.reorderGalleryItems(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            secondGroupId,
            isRequired: true,
          ),
          itemIds: [
            tenantAdminAccountProfilesRepoString(
              secondItemId,
              isRequired: true,
            ),
            tenantAdminAccountProfilesRepoString(firstItemId, isRequired: true),
          ],
        );
        expect(snapshot.groups.first.items.first.itemId, secondItemId);

        snapshot = await profilesRepository.updateGalleryItem(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            secondGroupId,
            isRequired: true,
          ),
          itemId: tenantAdminAccountProfilesRepoString(
            firstItemId,
            isRequired: true,
          ),
          type: TenantAdminAccountProfileGalleryItemType.youtube,
          description: TenantAdminOptionalTextValue()
            ..parse('Vídeo atualizado'),
        );
        expect(
          snapshot.groups.first.items
              .singleWhere((item) => item.itemId == firstItemId)
              .description,
          'Vídeo atualizado',
        );

        snapshot = await profilesRepository.deleteGalleryItem(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            secondGroupId,
            isRequired: true,
          ),
          itemId: tenantAdminAccountProfilesRepoString(
            secondItemId,
            isRequired: true,
          ),
        );
        expect(snapshot.groups.first.items.single.itemId, firstItemId);

        snapshot = await profilesRepository.deleteGalleryGroup(
          accountProfileId: profileId,
          groupId: tenantAdminAccountProfilesRepoString(
            firstGroupId,
            isRequired: true,
          ),
        );
        expect(snapshot.groups.single.groupId, secondGroupId);

        persistedProfile = await profilesRepository.fetchAccountProfile(
          profileId,
        );
        expect(persistedProfile.galleryGroups, hasLength(1));
        expect(persistedProfile.galleryGroups.single.groupId, secondGroupId);
        expect(persistedProfile.galleryGroups.single.items, hasLength(1));
        final persistedItem =
            persistedProfile.galleryGroups.single.items.single;
        expect(persistedItem.itemId, firstItemId);
        expect(
          persistedItem.type,
          TenantAdminAccountProfileGalleryItemType.youtube,
        );
        expect(persistedItem.description, 'Vídeo atualizado');

        final youtubeItem = persistedItem.toGalleryItem();
        await tester.pumpWidget(
          _GalleryRuntimeHarness(
            items: <GalleryItem>[
              const GalleryPhoto(itemId: 'photo-runtime', imageUrl: ''),
              youtubeItem,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BellugaGalleryPreviewRow), findsOneWidget);
        expect(find.byType(YoutubePlayer), findsNothing);
        await tester.tap(
          find.byKey(Key('bellugaGalleryPreview_${youtubeItem.itemId}')),
        );
        await tester.pumpAndSettle();

        expect(find.text('2/2'), findsOneWidget);
        expect(find.byType(YoutubePlayer), findsNothing);
        await tester.tap(find.byIcon(Icons.play_circle_fill));
        await _pumpFor(tester, const Duration(seconds: 3));
        expect(find.byType(YoutubePlayer), findsOneWidget);

        final pageController = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        pageController.jumpToPage(0);
        await _pumpFor(tester, const Duration(seconds: 2));
        expect(find.text('1/2'), findsOneWidget);
        expect(find.byType(YoutubePlayer), findsNothing);

        pageController.jumpToPage(1);
        await _pumpFor(tester, const Duration(seconds: 2));
        await tester.tap(find.byIcon(Icons.play_circle_fill));
        await _pumpFor(tester, const Duration(seconds: 2));
        expect(find.byType(YoutubePlayer), findsOneWidget);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        try {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 2)),
          );
        } finally {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
        }
        expect(find.byType(YoutubePlayer), findsNothing);
      } finally {
        if (accountSlug != null) {
          final slug = TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            accountSlug,
            isRequired: true,
          );
          await _deleteAccountFixture(accountsRepository, slug);
        }
        if (profileType != null) {
          await profilesRepository.deleteProfileType(
            tenantAdminAccountProfilesRepoString(profileType, isRequired: true),
          );
        }
        await GetIt.I.reset(dispose: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

final class _GalleryRuntimeHarness extends StatefulWidget {
  const _GalleryRuntimeHarness({required this.items});

  final List<GalleryItem> items;

  @override
  State<_GalleryRuntimeHarness> createState() => _GalleryRuntimeHarnessState();
}

final class _GalleryRuntimeHarnessState extends State<_GalleryRuntimeHarness> {
  int? initialIndex;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = initialIndex;
    return MaterialApp(
      home: Scaffold(
        body: selectedIndex == null
            ? BellugaGalleryPreviewRow(
                items: widget.items,
                onItemSelected: (index) => setState(() => initialIndex = index),
              )
            : BellugaGalleryViewer(
                items: widget.items,
                initialIndex: selectedIndex,
              ),
      ),
    );
  }
}

Future<void> _deleteAccountFixture(
  TenantAdminAccountsRepository accountsRepository,
  TenantAdminAccountsRepositoryContractPrimString slug,
) async {
  try {
    await accountsRepository.deleteAccount(slug);
  } on FormApiFailure catch (error) {
    if (error.statusCode == 404) {
      return;
    }
    rethrow;
  }

  try {
    await accountsRepository.forceDeleteAccount(slug);
  } on FormApiFailure catch (error) {
    if (error.statusCode != 404) {
      rethrow;
    }
  }
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _requireDefine(String key, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    fail('Missing --dart-define=$key for integration test execution.');
  }
  return normalized;
}

String _normalizeHost(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid tenant host value: "$raw"');
  }
  return uri.host.trim().toLowerCase();
}

String _deriveLandlordOriginFromTenantHost(String tenantHost) {
  final labels = tenantHost.trim().toLowerCase().split('.');
  if (labels.length < 2) {
    fail('Invalid tenant host for landlord derivation: "$tenantHost"');
  }
  final landlordHost = labels.length >= 3
      ? labels.sublist(1).join('.')
      : labels.join('.');
  return 'https://$landlordHost';
}

LandlordTenantOption _resolveTenantByDomain(
  List<LandlordTenantOption> tenants,
  String expectedHost,
) {
  for (final tenant in tenants) {
    if (_normalizeHost(tenant.mainDomain) == expectedHost) {
      return tenant;
    }
  }
  fail(
    'Tenant "$expectedHost" not found. Available: '
    '${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
  );
}
