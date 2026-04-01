import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class LocationOriginResolutionRequest {
  const LocationOriginResolutionRequest({
    required this.warmUpIfPossibleValue,
    required this.requestPermissionIfNeededValue,
    required this.forceTenantDefaultUnavailableValue,
    this.warmUpTimeoutValue,
    this.permissionTimeoutValue,
  });

  final DomainBooleanValue warmUpIfPossibleValue;
  final DomainBooleanValue requestPermissionIfNeededValue;
  final DomainBooleanValue forceTenantDefaultUnavailableValue;
  final UserLocationRepositoryContractDurationValue? warmUpTimeoutValue;
  final UserLocationRepositoryContractDurationValue? permissionTimeoutValue;

  bool get warmUpIfPossible => warmUpIfPossibleValue.value;
  bool get requestPermissionIfNeeded => requestPermissionIfNeededValue.value;
  bool get forceTenantDefaultUnavailable =>
      forceTenantDefaultUnavailableValue.value;
  Duration? get warmUpTimeout => warmUpTimeoutValue?.value;
  Duration? get permissionTimeout => permissionTimeoutValue?.value;
}
