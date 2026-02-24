import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: 'admin@bellugasolutions.com.br',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '765432e1',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: 'guarappari.belluga.space',
  );

  String requireDefine(String key, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      fail(
        'Missing --dart-define=$key for integration test execution.',
      );
    }
    return normalized;
  }

  String normalizeHost(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (uri == null || uri.host.trim().isEmpty) {
      fail('Invalid tenant host value: "$raw"');
    }
    return uri.host.trim().toLowerCase();
  }

  String mutateHexColor(
    String raw,
    int delta,
  ) {
    final normalized = raw.trim().toUpperCase();
    final match = RegExp(r'^#[0-9A-F]{6}$').firstMatch(normalized);
    if (match == null) {
      fail('Invalid color format from backend: $raw');
    }
    final numeric = int.parse(normalized.substring(1), radix: 16);
    var mutated = (numeric + delta) & 0x00FFFFFF;
    if (mutated == numeric) {
      mutated = (numeric + 1) & 0x00FFFFFF;
    }
    return '#${mutated.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  LandlordTenantOption resolveTenantByDomain(
    List<LandlordTenantOption> tenants,
    String expectedHost,
  ) {
    for (final tenant in tenants) {
      if (normalizeHost(tenant.mainDomain) == expectedHost) {
        return tenant;
      }
    }
    fail(
      'Tenant "$expectedHost" not found in landlord listing. '
      'Available: ${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
    );
  }

  Future<TenantAdminBrandingSettings> waitForBranding({
    required TenantAdminSettingsRepository repository,
    required bool Function(TenantAdminBrandingSettings value) predicate,
    required String expectationLabel,
    Duration timeout = const Duration(seconds: 40),
    Duration step = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    TenantAdminBrandingSettings? lastRead;

    while (DateTime.now().isBefore(deadline)) {
      final current = await repository.fetchBrandingSettings();
      lastRead = current;
      if (predicate(current)) {
        return current;
      }
      await Future<void>.delayed(step);
    }

    throw TestFailure(
      'Timed out waiting for $expectationLabel. '
      'Last read: primary=${lastRead?.primarySeedColor}, '
      'secondary=${lastRead?.secondarySeedColor}, '
      'brightness=${lastRead?.brightnessDefault.rawValue}.',
    );
  }

  testWidgets(
    'tenant admin branding update persists and reloads from tenant environment',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final adminEmail =
          requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine);
      final adminPassword =
          requireDefine('LANDLORD_ADMIN_PASSWORD', adminPasswordDefine);
      final expectedTenantHost = normalizeHost(tenantDomainDefine);

      final authRepository = LandlordAuthRepository();
      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);

      TenantAdminBrandingSettings? originalBranding;
      var mutationApplied = false;

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(adminEmail, adminPassword);
        expect(authRepository.hasValidSession, isTrue);

        final tenantsRepository =
            LandlordTenantsRepository(landlordAuthRepository: authRepository);
        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);

        final tenantOption = resolveTenantByDomain(tenants, expectedTenantHost);
        final tenantScopeRepository = TenantAdminSelectedTenantRepository();
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);

        expect(
          normalizeHost(tenantScopeRepository.selectedTenantDomain ?? ''),
          expectedTenantHost,
        );

        final settingsRepository = TenantAdminSettingsRepository(
          tenantScope: tenantScopeRepository,
        );

        originalBranding = await settingsRepository.fetchBrandingSettings();

        final mutatedPrimary = mutateHexColor(
          originalBranding.primarySeedColor,
          0x001111,
        );
        var mutatedSecondary = mutateHexColor(
          originalBranding.secondarySeedColor,
          0x002222,
        );
        if (mutatedSecondary == mutatedPrimary) {
          mutatedSecondary = mutateHexColor(mutatedSecondary, 0x000101);
        }
        final mutatedBrightness = originalBranding.brightnessDefault ==
                TenantAdminBrandingBrightness.dark
            ? TenantAdminBrandingBrightness.light
            : TenantAdminBrandingBrightness.dark;

        await settingsRepository.updateBranding(
          input: TenantAdminBrandingUpdateInput(
            tenantName: originalBranding.tenantName,
            brightnessDefault: mutatedBrightness,
            primarySeedColor: mutatedPrimary,
            secondarySeedColor: mutatedSecondary,
          ),
        );
        mutationApplied = true;

        final persisted = await waitForBranding(
          repository: settingsRepository,
          expectationLabel: 'mutated branding persistence',
          predicate: (value) {
            return value.primarySeedColor == mutatedPrimary &&
                value.secondarySeedColor == mutatedSecondary &&
                value.brightnessDefault == mutatedBrightness;
          },
        );

        expect(persisted.primarySeedColor, mutatedPrimary);
        expect(persisted.secondarySeedColor, mutatedSecondary);
        expect(persisted.brightnessDefault, mutatedBrightness);

        final freshReload = await settingsRepository.fetchBrandingSettings();
        expect(freshReload.primarySeedColor, mutatedPrimary);
        expect(freshReload.secondarySeedColor, mutatedSecondary);
        expect(freshReload.brightnessDefault, mutatedBrightness);
      } finally {
        if (mutationApplied && originalBranding != null) {
          final restoreRepository = TenantAdminSettingsRepository(
            tenantScope: TenantAdminSelectedTenantRepository()
              ..selectTenantDomain(tenantDomainDefine),
          );

          await restoreRepository.updateBranding(
            input: TenantAdminBrandingUpdateInput(
              tenantName: originalBranding.tenantName,
              brightnessDefault: originalBranding.brightnessDefault,
              primarySeedColor: originalBranding.primarySeedColor,
              secondarySeedColor: originalBranding.secondarySeedColor,
            ),
          );

          await waitForBranding(
            repository: restoreRepository,
            expectationLabel: 'branding restoration',
            predicate: (value) {
              return value.primarySeedColor ==
                      originalBranding!.primarySeedColor &&
                  value.secondarySeedColor ==
                      originalBranding.secondarySeedColor &&
                  value.brightnessDefault == originalBranding.brightnessDefault;
            },
          );
        }

        await authRepository.logout();
        await GetIt.I.reset(dispose: true);
      }
    },
  );
}
