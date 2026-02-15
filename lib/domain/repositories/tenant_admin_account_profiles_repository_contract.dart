import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

abstract class TenantAdminAccountProfilesRepositoryContract {
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  });
  Future<TenantAdminAccountProfile> fetchAccountProfile(String accountProfileId);
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });
  Future<void> deleteAccountProfile(String accountProfileId);
  Future<TenantAdminAccountProfile> restoreAccountProfile(String accountProfileId);
  Future<void> forceDeleteAccountProfile(String accountProfileId);
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes();
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final profileTypes = await fetchProfileTypes();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= profileTypes.length) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, profileTypes.length);
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: profileTypes.sublist(startIndex, endIndex),
      hasMore: endIndex < profileTypes.length,
    );
  }

  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  });
  Future<void> deleteProfileType(String type);
}
