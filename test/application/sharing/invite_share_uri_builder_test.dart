import 'package:belluga_now/application/sharing/invite_share_uri_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildInviteShareUri keeps canonical invite route when event context exists',
    () {
      final uri = buildInviteShareUri(
        origin: 'https://tenant.test',
        shareCode: 'CODE123',
        eventSlug: 'evento-de-teste',
        occurrenceId: 'occurrence-selected',
      );

      expect(uri, isNotNull);
      expect(uri!.toString(), 'https://tenant.test/invite?code=CODE123');
    },
  );

  test(
    'buildInviteShareUri omits fallback when canonical event path is absent',
    () {
      final uri = buildInviteShareUri(
        origin: 'https://tenant.test',
        shareCode: 'CODE123',
        eventSlug: '',
        occurrenceId: 'occurrence-selected',
      );

      expect(uri, isNotNull);
      expect(uri!.toString(), 'https://tenant.test/invite?code=CODE123');
    },
  );
}
