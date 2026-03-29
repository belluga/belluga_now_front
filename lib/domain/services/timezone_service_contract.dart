typedef TimezoneServiceContractPrimString = String;
typedef TimezoneServiceContractPrimInt = int;
typedef TimezoneServiceContractPrimBool = bool;
typedef TimezoneServiceContractPrimDouble = double;
typedef TimezoneServiceContractPrimDateTime = DateTime;
typedef TimezoneServiceContractPrimDynamic = dynamic;

abstract class TimezoneServiceContract {
  TimezoneServiceContractPrimDateTime utcToLocal(
    TimezoneServiceContractPrimDateTime value,
  );

  TimezoneServiceContractPrimDateTime localToUtc(
    TimezoneServiceContractPrimDateTime value,
  );
}
