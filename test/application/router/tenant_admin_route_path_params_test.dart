import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tenant admin routes path params', () {
    test(
      'event edit route encodes eventId path param and occurrence query',
      () {
        final eventEdit = TenantAdminEventEditRoute(
          eventId: 'evt-123',
          occurrenceId: 'occ-7',
        );

        expect(eventEdit.rawPathParams, {'eventId': 'evt-123'});
        expect(eventEdit.rawQueryParams['occurrence'], 'occ-7');
        _expectResolvedRawParams(eventEdit.rawPathParams);
      },
    );

    test('account profile create/edit routes encode required path params', () {
      final create = TenantAdminAccountProfileCreateRoute(
        accountSlug: 'john-doe',
      );
      final edit = TenantAdminAccountProfileEditRoute(
        accountSlug: 'john-doe',
        accountProfileId: 'profile-123',
      );

      expect(create.rawPathParams, {'accountSlug': 'john-doe'});
      expect(edit.rawPathParams, {
        'accountSlug': 'john-doe',
        'accountProfileId': 'profile-123',
      });
      _expectResolvedRawParams(create.rawPathParams);
      _expectResolvedRawParams(edit.rawPathParams);
    });

    test('organization detail encodes required path params', () {
      final organization = TenantAdminOrganizationDetailRoute(
        organizationId: 'org-123',
      );

      expect(organization.rawPathParams, {'organizationId': 'org-123'});
      _expectResolvedRawParams(organization.rawPathParams);
    });

    test('profile type routes encode profileType path param', () {
      final profileRoute = TenantAdminProfileTypeDetailRoute(
        profileType: 'artist',
      );
      final profileEditRoute = TenantAdminProfileTypeEditRoute(
        profileType: 'artist',
      );

      expect(profileRoute.rawPathParams, {'profileType': 'artist'});
      expect(profileEditRoute.rawPathParams, {'profileType': 'artist'});
      _expectResolvedRawParams(profileRoute.rawPathParams);
      _expectResolvedRawParams(profileEditRoute.rawPathParams);
    });

    test('taxonomy routes encode taxonomyId and termId path params', () {
      const taxonomyId = 'taxonomy-1';
      const termId = 'term-77';

      final taxonomyEdit = TenantAdminTaxonomyEditRoute(taxonomyId: taxonomyId);
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
    test('immersive event and partner routes encode path params', () {
      final immersive = ImmersiveEventDetailRoute(
        eventSlug: 'show-immersive',
        occurrenceId: 'occ-2',
      );
      final partner = PartnerDetailRoute(slug: 'yuri-dias');

      expect(immersive.rawPathParams, {'slug': 'show-immersive'});
      expect(immersive.rawQueryParams['occurrence'], 'occ-2');
      expect(immersive.rawQueryParams['tab'], isNull);
      expect(partner.rawPathParams, {'slug': 'yuri-dias'});
      _expectResolvedRawParams(immersive.rawPathParams);
      _expectResolvedRawParams(partner.rawPathParams);
    });
  });

  group('Workspace route path params', () {
    test('workspace scoped route encodes account slug path param', () {
      const workspaceHome = AccountWorkspaceHomeRoute();
      final workspaceScoped = AccountWorkspaceScopedRoute(
        accountSlug: 'account-alpha',
      );

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
