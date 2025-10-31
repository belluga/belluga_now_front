import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';

abstract class HomeRepositoryContract {
  BackendContract get backend;

  Future<HomeOverview> fetchOverview();
}
