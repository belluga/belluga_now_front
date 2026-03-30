import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:belluga_now/domain/services/value_objects/timezone_service_contract_values.dart';

class TimezoneService implements TimezoneServiceContract {
  @override
  TimezoneServiceContractDateTimeValue utcToLocal(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    if (!raw.isUtc) {
      return timezoneServiceDateTime(raw, defaultValue: raw);
    }
    return timezoneServiceDateTime(raw.toLocal(), defaultValue: raw.toLocal());
  }

  @override
  TimezoneServiceContractDateTimeValue localToUtc(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    if (raw.isUtc) {
      return timezoneServiceDateTime(raw, defaultValue: raw);
    }
    return timezoneServiceDateTime(raw.toUtc(), defaultValue: raw.toUtc());
  }
}
