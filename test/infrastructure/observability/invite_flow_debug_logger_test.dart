import 'package:belluga_now/infrastructure/observability/invite_flow_debug_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(InviteFlowDebugLogger.resetForTesting);

  test('sanitizes sensitive fields while preserving safe counters', () {
    final sanitized = InviteFlowDebugLogger.sanitizeFieldsForTesting({
      'contact_count': 12,
      'recipient_count': 4,
      'authorization': 'Bearer secret-token',
      'push_token': 'push-secret',
      'contacts': const ['a', 'b'],
      'response_keys': const ['matches', 'status'],
      'contact_type_counts': const {'phone': 10, 'email': 2},
      'auth_present': true,
    });

    expect(sanitized['contact_count'], 12);
    expect(sanitized['recipient_count'], 4);
    expect(sanitized['authorization'], '<redacted>');
    expect(sanitized['push_token'], '<redacted>');
    expect(sanitized['contacts'], '<redacted>');
    expect(sanitized['response_keys'], const ['matches', 'status']);
    expect(sanitized['contact_type_counts'], const {'phone': 10, 'email': 2});
    expect(sanitized['auth_present'], isTrue);
  });

  test('emits tagged JSON output with trace id', () {
    final messages = <String>[];
    InviteFlowDebugLogger.overrideWriterForTesting(messages.add);

    InviteFlowDebugLogger.log(
      'contacts.import.start',
      traceId: InviteFlowDebugLogger.nextTraceId('contacts.import'),
      fields: const {'contact_count': 3, 'authorization': 'Bearer hidden'},
    );

    expect(messages, hasLength(1));
    expect(messages.single, startsWith('[InviteFlowDebug] '));
    expect(messages.single, contains('"event":"contacts.import.start"'));
    expect(messages.single, contains('"trace_id":"contacts.import#1"'));
    expect(messages.single, contains('"contact_count":3'));
    expect(messages.single, contains('"authorization":"<redacted>"'));
  });
}
