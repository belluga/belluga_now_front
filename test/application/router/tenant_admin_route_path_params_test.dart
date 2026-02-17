import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tenant admin routes path params', () {
    test('account detail/create/edit routes encode required path params', () {
      final detail = TenantAdminAccountDetailRoute(accountSlug: 'john-doe');
      final create = TenantAdminAccountProfileCreateRoute(
        accountSlug: 'john-doe',
      );
      final edit = TenantAdminAccountProfileEditRoute(
        accountSlug: 'john-doe',
        accountProfileId: 'profile-123',
      );

      expect(detail.rawPathParams, {'accountSlug': 'john-doe'});
      expect(create.rawPathParams, {'accountSlug': 'john-doe'});
      expect(edit.rawPathParams, {
        'accountSlug': 'john-doe',
        'accountProfileId': 'profile-123',
      });
      _expectResolvedRawParams(detail.rawPathParams);
      _expectResolvedRawParams(create.rawPathParams);
      _expectResolvedRawParams(edit.rawPathParams);
    });

    test(
        'organization and static asset detail/edit encode required path params',
        () {
      final organization = TenantAdminOrganizationDetailRoute(
        organizationId: 'org-123',
      );
      final assetDetail =
          TenantAdminStaticAssetDetailRoute(assetId: 'asset-41');
      final assetEdit = TenantAdminStaticAssetEditRoute(assetId: 'asset-42');

      expect(organization.rawPathParams, {'organizationId': 'org-123'});
      expect(assetDetail.rawPathParams, {'assetId': 'asset-41'});
      expect(assetEdit.rawPathParams, {'assetId': 'asset-42'});
      _expectResolvedRawParams(organization.rawPathParams);
      _expectResolvedRawParams(assetDetail.rawPathParams);
      _expectResolvedRawParams(assetEdit.rawPathParams);
    });

    test('profile type routes encode profileType path param', () {
      const profileDefinition = TenantAdminProfileTypeDefinition(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: false,
          isPoiEnabled: false,
          hasBio: true,
          hasContent: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasEvents: true,
        ),
      );
      const staticDefinition = TenantAdminStaticProfileTypeDefinition(
        type: 'poi',
        label: 'POI',
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: true,
          hasBio: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasContent: true,
        ),
      );

      final profileRoute = TenantAdminProfileTypeDetailRoute(
        profileType: 'artist',
        definition: profileDefinition,
      );
      final profileEditRoute = TenantAdminProfileTypeEditRoute(
        profileType: 'artist',
        definition: profileDefinition,
      );
      final staticDetailRoute = TenantAdminStaticProfileTypeDetailRoute(
        profileType: 'poi',
        definition: staticDefinition,
      );
      final staticRoute = TenantAdminStaticProfileTypeEditRoute(
        profileType: 'poi',
        definition: staticDefinition,
      );

      expect(profileRoute.rawPathParams, {'profileType': 'artist'});
      expect(profileEditRoute.rawPathParams, {'profileType': 'artist'});
      expect(staticDetailRoute.rawPathParams, {'profileType': 'poi'});
      expect(staticRoute.rawPathParams, {'profileType': 'poi'});
      _expectResolvedRawParams(profileRoute.rawPathParams);
      _expectResolvedRawParams(profileEditRoute.rawPathParams);
      _expectResolvedRawParams(staticDetailRoute.rawPathParams);
      _expectResolvedRawParams(staticRoute.rawPathParams);
    });

    test('taxonomy routes encode taxonomyId and termId path params', () {
      const taxonomy = TenantAdminTaxonomyDefinition(
        id: 'taxonomy-1',
        slug: 'music-style',
        name: 'Music Style',
        appliesTo: ['account_profiles'],
        icon: null,
        color: null,
      );
      const term = TenantAdminTaxonomyTermDefinition(
        id: 'term-77',
        taxonomyId: 'taxonomy-1',
        slug: 'rock',
        name: 'Rock',
      );

      final taxonomyEdit = TenantAdminTaxonomyEditRoute(
        taxonomyId: taxonomy.id,
        taxonomy: taxonomy,
      );
      final taxonomyTerms = TenantAdminTaxonomyTermsRoute(
        taxonomyId: taxonomy.id,
        taxonomyName: taxonomy.name,
      );
      final termDetail = TenantAdminTaxonomyTermDetailRoute(
        taxonomyId: taxonomy.id,
        taxonomyName: taxonomy.name,
        termId: term.id,
        term: term,
      );
      final termEdit = TenantAdminTaxonomyTermEditRoute(
        taxonomyId: taxonomy.id,
        taxonomyName: taxonomy.name,
        termId: term.id,
        term: term,
      );
      final termCreate = TenantAdminTaxonomyTermCreateRoute(
        taxonomyId: taxonomy.id,
        taxonomyName: taxonomy.name,
      );

      expect(taxonomyEdit.rawPathParams, {'taxonomyId': taxonomy.id});
      expect(taxonomyTerms.rawPathParams, {'taxonomyId': taxonomy.id});
      expect(termDetail.rawPathParams, {
        'taxonomyId': taxonomy.id,
        'termId': term.id,
      });
      expect(termEdit.rawPathParams, {
        'taxonomyId': taxonomy.id,
        'termId': term.id,
      });
      expect(termCreate.rawPathParams, {'taxonomyId': taxonomy.id});
      _expectResolvedRawParams(taxonomyEdit.rawPathParams);
      _expectResolvedRawParams(taxonomyTerms.rawPathParams);
      _expectResolvedRawParams(termDetail.rawPathParams);
      _expectResolvedRawParams(termEdit.rawPathParams);
      _expectResolvedRawParams(termCreate.rawPathParams);
    });
  });

  group('Public route path params', () {
    test('event and partner routes encode slug path params', () {
      final eventDetail = EventDetailRoute(slug: 'rock-in-rio');
      final immersive = ImmersiveEventDetailRoute(eventSlug: 'show-immersive');
      final partner = PartnerDetailRoute(slug: 'yuri-dias');

      expect(eventDetail.rawPathParams, {'slug': 'rock-in-rio'});
      expect(immersive.rawPathParams, {'slug': 'show-immersive'});
      expect(partner.rawPathParams, {'slug': 'yuri-dias'});
      _expectResolvedRawParams(eventDetail.rawPathParams);
      _expectResolvedRawParams(immersive.rawPathParams);
      _expectResolvedRawParams(partner.rawPathParams);
    });
  });
}

void _expectResolvedRawParams(Map<String, dynamic> rawPathParams) {
  for (final value in rawPathParams.values) {
    expect(value, isNotNull);
    final text = value.toString();
    expect(text.trim(), isNotEmpty);
    expect(text.startsWith(':'), isFalse);
  }
}
