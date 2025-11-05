import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/domain/repositories/home_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController();

  final _homeRepository = GetIt.I.get<HomeRepositoryContract>();

  final StreamValue<HomeOverview?> overviewStreamValue =
      StreamValue<HomeOverview?>();

  Future<void> init() async {
    await loadOverview();
  }

  Future<void> loadOverview() async {
    final previousValue = overviewStreamValue.value;
    overviewStreamValue.addValue(null);
    try {
      final overview = await _homeRepository.fetchOverview();
      overviewStreamValue.addValue(overview);
    } catch (_) {
      overviewStreamValue.addValue(previousValue);
    }
  }

  @override
  void onDispose() {
    overviewStreamValue.dispose();
  }
}
