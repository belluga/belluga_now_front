import 'package:belluga_now/domain/services/value_objects/timezone_service_contract_values.dart';

typedef TimezoneServiceContractPrimDateTime = TimezoneServiceContractDateTimeValue;

abstract class TimezoneServiceContract {
  TimezoneServiceContractPrimDateTime utcToLocal(
    TimezoneServiceContractPrimDateTime value,
  );

  TimezoneServiceContractPrimDateTime localToUtc(
    TimezoneServiceContractPrimDateTime value,
  );
}
