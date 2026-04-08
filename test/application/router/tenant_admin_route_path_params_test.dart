import 'package:belluga_now/application/router/app_router.gr.dart';
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
      final profileRoute = TenantAdminProfileTypeDetailRoute(
        profileType: 'artist',
      );
      final profileEditRoute = TenantAdminProfileTypeEditRoute(
        profileType: 'artist',
      );
      final staticDetailRoute = TenantAdminStaticProfileTypeDetailRoute(
        profileType: 'poi',
      );
      final staticRoute = TenantAdminStaticProfileTypeEditRoute(
        profileType: 'poi',
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
      const taxonomyId = 'taxonomy-1';
      const termId = 'term-77';

      final taxonomyEdit = TenantAdminTaxonomyEditRoute(
        taxonomyId: taxonomyId,
      );
      final taxonomyTerms = TenantAdminTaxonomyTermsRoute(
        taxonomyId: taxonomyId,
      );
      final termDetail = TenantAdminTaxonomyTermDetailRoute(
        taxonomyId: taxonomyId,
        termId: termId,
      );
      final termEdit = TenantAdminTaxonomyTermEditRoute(
        taxonomyId: taxonomyId,
        termId: termId,
      );
      final termCreate = TenantAdminTaxonomyTermCreateRoute(
        taxonomyId: taxonomyId,
      );

      expect(taxonomyEdit.rawPathParams, {'taxonomyId': taxonomyId});
      expect(taxonomyTerms.rawPathParams, {'taxonomyId': taxonomyId});
      expect(termDetail.rawPathParams, {
        'taxonomyId': taxonomyId,
        'termId': termId,
      });
      expect(termEdit.rawPathParams, {
        'taxonomyId': taxonomyId,
        'termId': termId,
      });
      expect(termCreate.rawPathParams, {'taxonomyId': taxonomyId});
      _expectResolvedRawParams(taxonomyEdit.rawPathParams);
      _expectResolvedRawParams(taxonomyTerms.rawPathParams);
      _expectResolvedRawParams(termDetail.rawPathParams);
      _expectResolvedRawParams(termEdit.rawPathParams);
      _expectResolvedRawParams(termCreate.rawPathParams);
    });
  });

  group('Public route path params', () {
    test('immersive event, partner, and static asset routes encode path params',
        () {
      final immersive = ImmersiveEventDetailRoute(eventSlug: 'show-immersive');
      final partner = PartnerDetailRoute(slug: 'yuri-dias');
      final asset = StaticAssetDetailRoute(assetRef: 'praia-das-virtudes');

      expect(immersive.rawPathParams, {'slug': 'show-immersive'});
      expect(partner.rawPathParams, {'slug': 'yuri-dias'});
      expect(asset.rawPathParams, {'assetRef': 'praia-das-virtudes'});
      _expectResolvedRawParams(immersive.rawPathParams);
      _expectResolvedRawParams(partner.rawPathParams);
      _expectResolvedRawParams(asset.rawPathParams);
    });
  });

  group('Workspace route path params', () {
    test('workspace scoped route encodes account slug path param', () {
      const workspaceHome = AccountWorkspaceHomeRoute();
      final workspaceScoped =
          AccountWorkspaceScopedRoute(accountSlug: 'account-alpha');

      expect(workspaceHome.rawPathParams, isEmpty);
      expect(workspaceScoped.rawPathParams, {'accountSlug': 'account-alpha'});
      _expectResolvedRawParams(workspaceScoped.rawPathParams);
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
