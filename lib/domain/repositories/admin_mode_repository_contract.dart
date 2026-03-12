export 'admin_mode.dart';

import 'package:belluga_now/domain/repositories/admin_mode.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AdminModeRepositoryContract {
  StreamValue<AdminMode> get modeStreamValue;

  AdminMode get mode;

  bool get isLandlordMode;

  Future<void> init();

  Future<void> setUserMode();

  Future<void> setLandlordMode();
}
