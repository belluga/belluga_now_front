import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'encodes selected related account profiles as canonical event_parties payload',
      () {
    const encoder = TenantAdminEventsRequestEncoder();
    final payload = encoder.encodeDraft(
      TenantAdminEventDraft(
        titleValue: tenantAdminRequiredText('Evento'),
        contentValue: tenantAdminOptionalText('Conteudo'),
        type: TenantAdminEventType(
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        occurrences: [
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(
              DateTime(2026, 4, 5, 20),
            ),
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
        relatedAccountProfileIdValues: [
          TenantAdminAccountProfileIdValue('artist-1'),
          TenantAdminAccountProfileIdValue('artist-2'),
        ],
        relatedAccountProfiles: [
          tenantAdminAccountProfileFromRaw(
            id: 'artist-1',
            accountId: 'account-1',
            profileType: 'artist',
            displayName: 'Artist One',
            slug: 'artist-one',
            avatarUrl: 'https://tenant.test/artist-1-avatar.png',
            coverUrl: 'https://tenant.test/artist-1-cover.png',
            taxonomyTerms: (() {
              final terms = TenantAdminTaxonomyTerms();
              terms.add(
                tenantAdminTaxonomyTermFromRaw(
                  type: 'music_genre',
                  value: 'rock',
                ),
              );
              return terms;
            })(),
          ),
          tenantAdminAccountProfileFromRaw(
            id: 'artist-2',
            accountId: 'account-2',
            profileType: 'band',
            displayName: 'Artist Two',
            slug: 'artist-two',
          ),
        ],
      ),
    );

    expect(payload.containsKey('artist_ids'), isFalse);
    expect(payload.containsKey('artists'), isFalse);
    expect(payload.containsKey('artistProfiles'), isFalse);
    expect(payload['event_parties'], [
      {
        'party_type': 'artist',
        'party_ref_id': 'artist-1',
        'permissions': {'can_edit': true},
        'metadata': {
          'display_name': 'Artist One',
          'slug': 'artist-one',
          'profile_type': 'artist',
          'avatar_url': 'https://tenant.test/artist-1-avatar.png',
          'cover_url': 'https://tenant.test/artist-1-cover.png',
          'taxonomy_terms': [
            {
              'type': 'music_genre',
              'value': 'rock',
            },
          ],
        },
      },
      {
        'party_type': 'band',
        'party_ref_id': 'artist-2',
        'permissions': {'can_edit': true},
        'metadata': {
          'display_name': 'Artist Two',
          'slug': 'artist-two',
          'profile_type': 'band',
          'avatar_url': null,
          'cover_url': null,
          'taxonomy_terms': [],
        },
      },
    ]);
  });
}
