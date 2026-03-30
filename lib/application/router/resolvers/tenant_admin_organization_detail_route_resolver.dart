import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminOrganizationDetailRouteResolver
    implements RouteModelResolver<TenantAdminOrganization> {
  TenantAdminOrganizationDetailRouteResolver({
    @visibleForTesting
    TenantAdminOrganizationsRepositoryContract? organizationsRepository,
  }) : _organizationsRepository = organizationsRepository ??
            GetIt.I.get<TenantAdminOrganizationsRepositoryContract>();

  final TenantAdminOrganizationsRepositoryContract _organizationsRepository;

  @override
  Future<TenantAdminOrganization> resolve(RouteResolverParams params) async {
    final organizationId = params['organizationId'] as String?;
    if (organizationId == null || organizationId.trim().isEmpty) {
      throw ArgumentError.value(
        organizationId,
        'organizationId',
        'Organization id must be provided',
      );
    }

    return _organizationsRepository.fetchOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString.fromRaw(
        organizationId,
      ),
    );
  }
}
