import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminEventEditRouteResolver
    implements RouteModelResolver<TenantAdminEvent> {
  TenantAdminEventEditRouteResolver({
    @visibleForTesting
    TenantAdminEventsRepositoryContract? eventsRepository,
  }) : _eventsRepository =
            eventsRepository ?? GetIt.I.get<TenantAdminEventsRepositoryContract>();

  final TenantAdminEventsRepositoryContract _eventsRepository;

  @override
  Future<TenantAdminEvent> resolve(RouteResolverParams params) async {
    final eventId = params['eventId'] as String?;
    if (eventId == null || eventId.trim().isEmpty) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'Event id must be provided',
      );
    }

    return _eventsRepository.fetchEvent(
      TenantAdminEventsRepoString.fromRaw(
        eventId.trim(),
        defaultValue: '',
        isRequired: true,
      ),
    );
  }
}
