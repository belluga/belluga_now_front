import 'package:belluga_now/application/router/resolvers/tenant_admin_event_edit_route_resolver.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventsRepository extends Fake
    implements TenantAdminEventsRepositoryContract {
  _FakeEventsRepository({
    this.expectedEvent,
  });

  final TenantAdminEvent? expectedEvent;
  String? lastRequestedEventId;

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    lastRequestedEventId = eventIdOrSlug.value;
    if (expectedEvent == null) {
      throw StateError('No expected event configured');
    }
    return expectedEvent!;
  }
}

void main() {
  group('TenantAdminEventEditRouteResolver', () {
    test('loads event readback from route eventId', () async {
      final expected = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-1'),
        slugValue: tenantAdminRequiredText('evento-1'),
        titleValue: tenantAdminRequiredText('Evento 1'),
        contentValue: tenantAdminOptionalText('Conteudo'),
        type: TenantAdminEventType(
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 4, 20)),
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
      );
      final repository = _FakeEventsRepository(expectedEvent: expected);
      final resolver = TenantAdminEventEditRouteResolver(
        eventsRepository: repository,
      );

      final resolved = await resolver.resolve({'eventId': 'evt-1'});

      expect(resolved, same(expected));
      expect(repository.lastRequestedEventId, 'evt-1');
    });

    test('throws when eventId is missing', () async {
      final repository = _FakeEventsRepository();
      final resolver = TenantAdminEventEditRouteResolver(
        eventsRepository: repository,
      );

      await expectLater(
        () => resolver.resolve(<String, dynamic>{}),
        throwsA(isA<ArgumentError>()),
      );
      expect(repository.lastRequestedEventId, isNull);
    });
  });
}
