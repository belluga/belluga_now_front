import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_link_route_resolver.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_links_capability_disabled_route_exception.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

final class _FakeProfilesRepository extends Fake
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeProfilesRepository(this.profile);

  final TenantAdminAccountProfile profile;

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async => profile;
}

class _MockAccountsRepository extends Mock
    implements TenantAdminAccountsRepositoryContract {}

class _MockTaxonomiesRepository extends Mock
    implements TenantAdminTaxonomiesRepositoryContract {}

void main() {
  TenantAdminAccountProfilesController controllerFor(
    TenantAdminAccountProfilesRepositoryContract repository,
  ) => TenantAdminAccountProfilesController(
    profilesRepository: repository,
    accountsRepository: _MockAccountsRepository(),
    taxonomiesRepository: _MockTaxonomiesRepository(),
    locationSelectionService: TenantAdminLocationSelectionService(),
  );

  test(
    'hydrates the profile and initializes the matching edit draft',
    () async {
      final link = AccountProfileExternalLinkRegistry.validateMutation(
        id: AccountProfileExternalLinkIdValue('link-1'),
        type: AccountProfileExternalLinkType.instagram,
        url: AccountProfileExternalLinkUrlValue(
          'https://instagram.com/belluga',
        ),
      );
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'account-1',
        profileType: 'custom',
        displayName: 'Profile',
        externalLinks: [link],
        externalLinksLimit: 3,
      );
      final repository = _FakeProfilesRepository(profile);
      final controller = controllerFor(repository);
      final resolver = TenantAdminAccountProfileExternalLinkRouteResolver(
        accountProfilesRepository: repository,
        accountProfilesController: controller,
      );

      final model = await resolver.resolve({
        'accountSlug': 'account-one',
        'accountProfileId': 'profile-1',
        'externalLinkId': 'link-1',
      });

      expect(model.profile, same(profile));
      expect(model.draft.accountProfileId, 'profile-1');
      expect(model.draft.externalLinkId, 'link-1');
      expect(model.draft.routeGeneration, greaterThan(0));
      controller.endExternalLinkDraft(model.draft);
      controller.dispose();
    },
  );

  test(
    'fails closed before draft creation when capability is disabled',
    () async {
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'account-1',
        profileType: 'custom',
        displayName: 'Profile',
      );
      final repository = _FakeProfilesRepository(profile);
      final controller = controllerFor(repository);
      final resolver = TenantAdminAccountProfileExternalLinkRouteResolver(
        accountProfilesRepository: repository,
        accountProfilesController: controller,
      );

      await expectLater(
        resolver.resolve({
          'accountSlug': 'account-one',
          'accountProfileId': 'profile-1',
        }),
        throwsA(
          isA<
            TenantAdminAccountProfileExternalLinksCapabilityDisabledRouteException
          >(),
        ),
      );
      controller.dispose();
    },
  );
}
