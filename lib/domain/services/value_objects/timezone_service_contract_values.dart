export 'timezone_service_contract_date_time_value.dart';

import 'timezone_service_contract_date_time_value.dart';

TimezoneServiceContractDateTimeValue timezoneServiceDateTime(
  Object? raw, {
  DateTime? defaultValue,
  bool isRequired = true,
}) {
  if (raw is TimezoneServiceContractDateTimeValue) {
    return raw;
  }
  return TimezoneServiceContractDateTimeValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}
