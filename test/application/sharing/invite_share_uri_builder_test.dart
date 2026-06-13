import 'package:belluga_now/application/sharing/invite_share_uri_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildInviteShareUri includes canonical event fallback when available', () {
    final uri = buildInviteShareUri(
      origin: 'https://tenant.test',
      shareCode: 'CODE123',
      eventSlug: 'evento-de-teste',
      occurrenceId: 'occurrence-selected',
    );

    expect(uri, isNotNull);
    expect(
      uri!.toString(),
      'https://tenant.test/invite?code=CODE123&fallback=%2Fagenda%2Fevento%2Fevento-de-teste%3Foccurrence%3Doccurrence-selected',
    );
  });

  test('buildInviteShareUri omits fallback when canonical event path is absent', () {
    final uri = buildInviteShareUri(
      origin: 'https://tenant.test',
      shareCode: 'CODE123',
      eventSlug: '',
      occurrenceId: 'occurrence-selected',
    );

    expect(uri, isNotNull);
    expect(uri!.toString(), 'https://tenant.test/invite?code=CODE123');
  });
}
