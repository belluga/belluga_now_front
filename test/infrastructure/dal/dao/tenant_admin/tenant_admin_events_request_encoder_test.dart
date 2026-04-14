import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'encodes selected related account profiles as minimal canonical event_parties payload',
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
      ),
    );

    expect(payload.containsKey('artist_ids'), isFalse);
    expect(payload.containsKey('artists'), isFalse);
    expect(payload.containsKey('artistProfiles'), isFalse);
    expect(payload['event_parties'], [
      {
        'party_ref_id': 'artist-1',
        'permissions': {'can_edit': true},
      },
      {
        'party_ref_id': 'artist-2',
        'permissions': {'can_edit': true},
      },
    ]);
  });

  test(
      'encodes empty canonical event_parties payload when no related account profiles are selected',
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
      ),
    );

    expect(payload.containsKey('event_parties'), isTrue);
    expect(payload['event_parties'], isEmpty);
  });
}
