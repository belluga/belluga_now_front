import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminShellController implements Disposable {
  TenantAdminShellController({
    AdminModeRepositoryContract? adminModeRepository,
  }) : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>();

  final AdminModeRepositoryContract _adminModeRepository;

  StreamValue<AdminMode> get modeStreamValue =>
      _adminModeRepository.modeStreamValue;

  Future<void> switchToUserMode() => _adminModeRepository.setUserMode();

  @override
  void onDispose() {}
}
