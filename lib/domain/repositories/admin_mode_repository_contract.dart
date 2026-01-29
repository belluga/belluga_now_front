import 'package:stream_value/core/stream_value.dart';

enum AdminMode {
  user,
  landlord,
}

abstract class AdminModeRepositoryContract {
  StreamValue<AdminMode> get modeStreamValue;

  AdminMode get mode;

  bool get isLandlordMode;

  Future<void> init();

  Future<void> setUserMode();

  Future<void> setLandlordMode();
}
