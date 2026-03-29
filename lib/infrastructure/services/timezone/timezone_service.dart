import 'package:belluga_now/domain/services/timezone_service_contract.dart';

class TimezoneService implements TimezoneServiceContract {
  @override
  DateTime utcToLocal(DateTime value) {
    if (!value.isUtc) {
      return value;
    }
    return value.toLocal();
  }

  @override
  DateTime localToUtc(DateTime value) {
    if (value.isUtc) {
      return value;
    }
    return value.toUtc();
  }
}
