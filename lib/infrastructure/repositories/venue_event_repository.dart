import 'package:belluga_now/domain/repositories/venue_event_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/mappers/home_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:get_it/get_it.dart';

class VenueEventRepository extends VenueEventRepositoryContract
    with HomeDtoMapper {
  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    final List<HomeEventDTO> dtos = await backend.home.fetchFeaturedEvents();
    return dtos.map(mapVenueEventResume).toList(growable: false);
  }

  BackendContract get backend => GetIt.I.get<BackendContract>();
}
