import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/domain/repositories/home_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_overview_dto.dart';
import 'package:get_it/get_it.dart';

class HomeRepository extends HomeRepositoryContract {
  @override
  Future<HomeOverview> fetchOverview() async {
    final HomeOverviewDTO dto = await backend.home.fetchOverview();
    return HomeOverview.fromDTO(dto);
  }

  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();
}
