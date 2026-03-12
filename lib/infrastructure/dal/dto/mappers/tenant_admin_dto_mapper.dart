import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_organization_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_asset_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_profile_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_definition_dto.dart';

mixin TenantAdminDtoMapper {
  TenantAdminAccount mapTenantAdminAccountJson(Map<String, dynamic> json) {
    return mapTenantAdminAccountDto(TenantAdminAccountDTO.fromJson(json));
  }

  TenantAdminAccount mapTenantAdminAccountDto(TenantAdminAccountDTO dto) {
    final ownershipStateRaw = dto.ownershipState?.trim();
    final ownershipState =
        (ownershipStateRaw == null || ownershipStateRaw.isEmpty)
            ? TenantAdminOwnershipState.unmanaged
            : TenantAdminOwnershipState.fromApiValue(ownershipStateRaw);
    return TenantAdminAccount(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      document: TenantAdminDocument(
        type: dto.documentType,
        number: dto.documentNumber,
      ),
      organizationId: dto.organizationId,
      ownershipState: ownershipState,
      avatarUrl: dto.avatarUrl,
    );
  }

  TenantAdminAccountProfile mapTenantAdminAccountProfileJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminAccountProfileDto(
      TenantAdminAccountProfileDTO.fromJson(json),
    );
  }

  TenantAdminAccountProfile mapTenantAdminAccountProfileDto(
    TenantAdminAccountProfileDTO dto,
  ) {
    final location = (dto.locationLat != null && dto.locationLng != null)
        ? TenantAdminLocation(
            latitude: dto.locationLat!,
            longitude: dto.locationLng!,
          )
        : null;
    final taxonomy = dto.taxonomyTerms
        .map(
          (term) => TenantAdminTaxonomyTerm(
            type: term.type,
            value: term.value,
          ),
        )
        .toList(growable: false);
    return TenantAdminAccountProfile(
      id: dto.id,
      accountId: dto.accountId,
      profileType: dto.profileType,
      displayName: dto.displayName,
      slug: dto.slug,
      avatarUrl: dto.avatarUrl,
      coverUrl: dto.coverUrl,
      bio: dto.bio,
      content: dto.content,
      location: location,
      taxonomyTerms: taxonomy,
      ownershipState: dto.ownershipState == null
          ? null
          : TenantAdminOwnershipState.fromApiValue(dto.ownershipState),
    );
  }

  TenantAdminProfileTypeDefinition mapTenantAdminProfileTypeJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminProfileTypeDto(TenantAdminProfileTypeDTO.fromJson(json));
  }

  TenantAdminProfileTypeDefinition mapTenantAdminProfileTypeDto(
    TenantAdminProfileTypeDTO dto,
  ) {
    return TenantAdminProfileTypeDefinition(
      type: dto.type,
      label: dto.label,
      allowedTaxonomies: dto.allowedTaxonomies,
      capabilities: TenantAdminProfileTypeCapabilities(
        isFavoritable: dto.isFavoritable,
        isPoiEnabled: dto.isPoiEnabled,
        hasBio: dto.hasBio,
        hasContent: dto.hasContent,
        hasTaxonomies: dto.hasTaxonomies,
        hasAvatar: dto.hasAvatar,
        hasCover: dto.hasCover,
        hasEvents: dto.hasEvents,
      ),
    );
  }

  TenantAdminOrganization mapTenantAdminOrganizationJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminOrganizationDto(TenantAdminOrganizationDTO.fromJson(json));
  }

  TenantAdminOrganization mapTenantAdminOrganizationDto(
    TenantAdminOrganizationDTO dto,
  ) {
    return TenantAdminOrganization(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      description: dto.description,
    );
  }

  TenantAdminTaxonomyDefinition mapTenantAdminTaxonomyJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminTaxonomyDto(TenantAdminTaxonomyDTO.fromJson(json));
  }

  TenantAdminTaxonomyDefinition mapTenantAdminTaxonomyDto(
    TenantAdminTaxonomyDTO dto,
  ) {
    return TenantAdminTaxonomyDefinition(
      id: dto.id,
      slug: dto.slug,
      name: dto.name,
      appliesTo: dto.appliesTo,
      icon: dto.icon,
      color: dto.color,
    );
  }

  TenantAdminTaxonomyTermDefinition mapTenantAdminTaxonomyTermDefinitionJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminTaxonomyTermDefinitionDto(
      TenantAdminTaxonomyTermDefinitionDTO.fromJson(json),
    );
  }

  TenantAdminTaxonomyTermDefinition mapTenantAdminTaxonomyTermDefinitionDto(
    TenantAdminTaxonomyTermDefinitionDTO dto,
  ) {
    return TenantAdminTaxonomyTermDefinition(
      id: dto.id,
      taxonomyId: dto.taxonomyId,
      slug: dto.slug,
      name: dto.name,
    );
  }

  TenantAdminStaticAsset mapTenantAdminStaticAssetJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminStaticAssetDto(TenantAdminStaticAssetDTO.fromJson(json));
  }

  TenantAdminStaticAsset mapTenantAdminStaticAssetDto(
    TenantAdminStaticAssetDTO dto,
  ) {
    final location = (dto.locationLat != null && dto.locationLng != null)
        ? TenantAdminLocation(
            latitude: dto.locationLat!,
            longitude: dto.locationLng!,
          )
        : null;
    final taxonomy = dto.taxonomyTerms
        .map(
          (term) => TenantAdminTaxonomyTerm(
            type: term.type,
            value: term.value,
          ),
        )
        .toList(growable: false);
    return TenantAdminStaticAsset(
      id: dto.id,
      profileType: dto.profileType,
      displayName: dto.displayName,
      slug: dto.slug,
      avatarUrl: dto.avatarUrl,
      coverUrl: dto.coverUrl,
      bio: dto.bio,
      content: dto.content,
      tags: dto.tags,
      categories: dto.categories,
      taxonomyTerms: taxonomy,
      location: location,
      isActive: dto.isActive,
    );
  }

  TenantAdminStaticProfileTypeDefinition mapTenantAdminStaticProfileTypeJson(
    Map<String, dynamic> json,
  ) {
    return mapTenantAdminStaticProfileTypeDto(
      TenantAdminStaticProfileTypeDTO.fromJson(json),
    );
  }

  TenantAdminStaticProfileTypeDefinition mapTenantAdminStaticProfileTypeDto(
    TenantAdminStaticProfileTypeDTO dto,
  ) {
    return TenantAdminStaticProfileTypeDefinition(
      type: dto.type,
      label: dto.label,
      allowedTaxonomies: dto.allowedTaxonomies,
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: dto.isPoiEnabled,
        hasBio: dto.hasBio,
        hasTaxonomies: dto.hasTaxonomies,
        hasAvatar: dto.hasAvatar,
        hasCover: dto.hasCover,
        hasContent: dto.hasContent,
      ),
    );
  }
}
