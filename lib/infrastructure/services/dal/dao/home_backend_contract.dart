import 'package:belluga_now/infrastructure/services/dal/dto/home/home_overview_dto.dart';

abstract class HomeBackendContract {
  Future<HomeOverviewDTO> fetchOverview();
}
