import 'package:belluga_now/application/router/support/tenant_public_event_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildTenantPublicEventPath returns null when slug is blank', () {
    final result = buildTenantPublicEventPath(
      eventSlug: '   ',
      occurrenceId: 'occ-1',
    );

    expect(result, isNull);
  });

  test(
      'buildTenantPublicEventPath keeps base event path when occurrence is blank',
      () {
    final result = buildTenantPublicEventPath(
      eventSlug: 'show-rock',
      occurrenceId: '   ',
    );

    expect(result, '/agenda/evento/show-rock');
  });

  test('buildTenantPublicEventPath appends selected occurrence query', () {
    final result = buildTenantPublicEventPath(
      eventSlug: 'show-rock',
      occurrenceId: 'occ-1',
    );

    expect(result, '/agenda/evento/show-rock?occurrence=occ-1');
  });
}
