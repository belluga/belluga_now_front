import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LandlordHomeScreenController implements Disposable {
  LandlordHomeScreenController({
    AdminModeRepositoryContract? adminModeRepository,
  }) : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>();

  final AdminModeRepositoryContract _adminModeRepository;

  StreamValue<AdminMode> get modeStreamValue =>
      _adminModeRepository.modeStreamValue;

  bool get isLandlordMode => _adminModeRepository.isLandlordMode;

  Future<void> init() async {
    await _adminModeRepository.init();
  }

  @override
  void onDispose() {}
}
