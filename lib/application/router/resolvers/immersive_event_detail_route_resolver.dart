import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class ImmersiveEventDetailRouteResolver
    implements RouteModelResolver<EventModel> {
  ImmersiveEventDetailRouteResolver({
    @visibleForTesting ScheduleRepositoryContract? scheduleRepository,
  }) : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;

  @override
  Future<EventModel> resolve(RouteResolverParams params) async {
    final slug = params['slug'] as String?;
    if (slug == null || slug.isEmpty) {
      throw ArgumentError.value(
        slug,
        'slug',
        'Event slug must be provided',
      );
    }
    final event = await _scheduleRepository.getEventBySlug(slug);
    if (event == null) {
      throw Exception('Event not found for slug: $slug');
    }
    return event;
  }
}
