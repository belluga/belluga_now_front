import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository(this._types);

  List<TenantAdminProfileTypeDefinition> _types;
  int deleteCalls = 0;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    final created = TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    _types = [..._types, created];
    return created;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: false,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {
    deleteCalls += 1;
    _types = _types.where((entry) => entry.type != type).toList();
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async =>
      const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}
}

void main() {
  test('createType reloads registry list', () async {
    final repository = _FakeAccountProfilesRepository(const []);
    final controller = TenantAdminProfileTypesController(repository: repository);

    await controller.createType(
      type: 'venue',
      label: 'Venue',
      allowedTaxonomies: const [],
      capabilities: const TenantAdminProfileTypeCapabilities(
        isFavoritable: true,
        isPoiEnabled: true,
      ),
    );

    expect(controller.typesStreamValue.value.length, 1);
  });

  test('deleteType removes entry', () async {
    final repository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
        ),
      ),
    ]);
    final controller = TenantAdminProfileTypesController(repository: repository);

    await controller.loadTypes();
    expect(controller.typesStreamValue.value.length, 1);

    await controller.deleteType('venue');

    expect(repository.deleteCalls, 1);
    expect(controller.typesStreamValue.value.length, 0);
  });
}
