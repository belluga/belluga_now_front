import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:belluga_now/domain/services/value_objects/timezone_service_contract_values.dart';
import 'package:get_it/get_it.dart';

class TimezoneConverter {
  const TimezoneConverter._();

  static DateTime utcToLocal(DateTime value) {
    final service = _resolveService();
    if (service != null) {
      return service
          .utcToLocal(
            timezoneServiceDateTime(value, defaultValue: value),
          )
          .value;
    }
    return value.isUtc ? value.toLocal() : value;
  }

  static DateTime localToUtc(DateTime value) {
    final service = _resolveService();
    if (service != null) {
      return service
          .localToUtc(
            timezoneServiceDateTime(value, defaultValue: value),
          )
          .value;
    }
    return value.isUtc ? value : value.toUtc();
  }

  static TimezoneServiceContract? _resolveService() {
    if (!GetIt.I.isRegistered<TimezoneServiceContract>()) {
      return null;
    }
    return GetIt.I.get<TimezoneServiceContract>();
  }
}
