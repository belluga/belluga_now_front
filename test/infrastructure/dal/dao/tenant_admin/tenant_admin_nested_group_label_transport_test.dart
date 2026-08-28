import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_request_correlation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accountEncoder = TenantAdminAccountProfilesRequestEncoder();
  const eventEncoder = TenantAdminEventsRequestEncoder();

  test('encodes normalized label for both rename authorities', () {
    expect(
      accountEncoder.encodePatchNestedProfileGroupLabel(label: ' Partners '),
      {'label': 'Partners'},
    );
    expect(
      eventEncoder.encodePatchOccurrenceProfileGroupLabel(label: ' Artists '),
      {'label': 'Artists'},
    );
  });

  test('uses one generated request id without idempotency replay headers', () {
    final headers = TenantAdminRequestCorrelation.create().headers();
    expect(headers['X-Request-Id'], isNotEmpty);
    expect(headers, hasLength(1));
    expect(headers, isNot(contains('Idempotency-Key')));
  });

  test('decodes scalar authoritative account-profile group response', () {
    final group = const TenantAdminAccountProfilesResponseDecoder()
        .decodeNestedGroupLabelMutationResult({
          'data': {
            'group': {'id': 'partners', 'label': 'Partners'},
          },
        });
    expect(group.id, 'partners');
    expect(group.label, 'Partners');
  });

  test('decodes scalar authoritative event-occurrence group response', () {
    final group = const TenantAdminEventsResponseDecoder()
        .decodeOccurrenceGroupLabelMutationResult({
          'data': {
            'group': {'id': 'artists', 'label': 'Artists'},
          },
        });
    expect(group.id, 'artists');
    expect(group.label, 'Artists');
  });

  test('rejects non-scalar identifiers and labels for both authorities', () {
    final malformed = {
      'data': {
        'group': {
          'id': {'nested': 'id'},
          'label': ['nested', 'label'],
        },
      },
    };
    expect(
      () => const TenantAdminAccountProfilesResponseDecoder()
          .decodeNestedGroupLabelMutationResult(malformed),
      throwsFormatException,
    );
    expect(
      () => const TenantAdminEventsResponseDecoder()
          .decodeOccurrenceGroupLabelMutationResult(malformed),
      throwsFormatException,
    );
  });

  test('rejects missing scalar mutation fields', () {
    for (final group in <Map<String, Object?>>[
      {'id': 'g'},
      {'label': 'Group'},
      {'id': '', 'label': 'Group'},
    ]) {
      final response = {
        'data': {'group': group},
      };
      expect(
        () => const TenantAdminAccountProfilesResponseDecoder()
            .decodeNestedGroupLabelMutationResult(response),
        throwsFormatException,
      );
      expect(
        () => const TenantAdminEventsResponseDecoder()
            .decodeOccurrenceGroupLabelMutationResult(response),
        throwsFormatException,
      );
    }
    for (final response in <Map<String, Object?>>[
      {'data': <String, Object?>{}},
      {
        'data': {'group': 'not-a-map'},
      },
    ]) {
      expect(
        () => const TenantAdminAccountProfilesResponseDecoder()
            .decodeNestedGroupLabelMutationResult(response),
        throwsFormatException,
      );
      expect(
        () => const TenantAdminEventsResponseDecoder()
            .decodeOccurrenceGroupLabelMutationResult(response),
        throwsFormatException,
      );
    }
  });
}
