import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_link_route_model.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_links_capability_disabled_route_exception.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

final class TenantAdminAccountProfileExternalLinkRouteResolver
    implements
        RouteModelResolver<TenantAdminAccountProfileExternalLinkRouteModel> {
  TenantAdminAccountProfileExternalLinkRouteResolver({
    @visibleForTesting
    TenantAdminAccountProfilesRepositoryContract? accountProfilesRepository,
    @visibleForTesting
    TenantAdminAccountProfilesController? accountProfilesController,
  }) : _accountProfilesRepository =
           accountProfilesRepository ??
           GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
       _accountProfilesController =
           accountProfilesController ??
           GetIt.I.get<TenantAdminAccountProfilesController>();

  final TenantAdminAccountProfilesRepositoryContract _accountProfilesRepository;
  final TenantAdminAccountProfilesController _accountProfilesController;

  @override
  Future<TenantAdminAccountProfileExternalLinkRouteModel> resolve(
    RouteResolverParams params,
  ) async {
    final accountSlug = params['accountSlug'] as String?;
    final accountProfileId = params['accountProfileId'] as String?;
    final externalLinkId = params['externalLinkId'] as String?;
    if (accountSlug == null || accountSlug.trim().isEmpty) {
      throw ArgumentError.value(accountSlug, 'accountSlug');
    }
    if (accountProfileId == null || accountProfileId.trim().isEmpty) {
      throw ArgumentError.value(accountProfileId, 'accountProfileId');
    }

    final profile = await _accountProfilesRepository.fetchAccountProfile(
      tenantAdminAccountProfilesRepoString(
        accountProfileId.trim(),
        defaultValue: '',
        isRequired: true,
      ),
    );
    if (profile.externalLinksLimit == null) {
      throw const TenantAdminAccountProfileExternalLinksCapabilityDisabledRouteException();
    }

    AccountProfileExternalLink? existingLink;
    if (externalLinkId != null) {
      final normalizedId = externalLinkId.trim();
      if (normalizedId.isEmpty) {
        throw ArgumentError.value(externalLinkId, 'externalLinkId');
      }
      for (final link in profile.externalLinks) {
        if (link.id == normalizedId) {
          existingLink = link;
          break;
        }
      }
      if (existingLink == null) {
        throw StateError('The external link does not exist.');
      }
    }

    _accountProfilesController.adoptExternalLinkRouteProfile(profile);
    final draft = _accountProfilesController.beginExternalLinkDraft(
      accountProfileId: profile.id,
      existingLink: existingLink,
    );
    return TenantAdminAccountProfileExternalLinkRouteModel(
      profile: profile,
      draft: draft,
    );
  }
}
