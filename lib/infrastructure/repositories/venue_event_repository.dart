import 'package:belluga_now/domain/repositories/venue_event_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/mappers/venue_event_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:get_it/get_it.dart';

class VenueEventRepository extends VenueEventRepositoryContract
    with VenueEventDtoMapper {
  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    final List<HomeEventDTO> dtos = await backend.home.fetchFeaturedEvents();
    return dtos.map(mapVenueEventResume).toList(growable: false);
  }

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async {
    final List<HomeEventDTO> dtos = await backend.home.fetchUpcomingEvents();
    return dtos.map(mapVenueEventResume).toList(growable: false);
  }

  BackendContract get backend => GetIt.I.get<BackendContract>();
}
