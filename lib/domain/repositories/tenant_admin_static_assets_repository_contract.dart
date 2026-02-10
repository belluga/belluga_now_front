import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

abstract class TenantAdminStaticAssetsRepositoryContract {
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets();

  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId);

  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    required String slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
    List<String> categories = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    required bool isActive,
  });

  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    List<String>? categories,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    bool? isActive,
  });

  Future<void> deleteStaticAsset(String assetId);

  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId);

  Future<void> forceDeleteStaticAsset(String assetId);

  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes();

  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  });

  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  });

  Future<void> deleteStaticProfileType(String type);
}
