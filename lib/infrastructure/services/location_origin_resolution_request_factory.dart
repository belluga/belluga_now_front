import 'package:belluga_now/domain/app_data/location_origin_resolution_request.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class LocationOriginResolutionRequestFactory {
  static LocationOriginResolutionRequest create({
    bool warmUpIfPossible = false,
    bool requestPermissionIfNeeded = false,
    bool forceTenantDefaultUnavailable = false,
    Duration? warmUpTimeout,
    Duration? permissionTimeout,
  }) {
    return LocationOriginResolutionRequest(
      warmUpIfPossibleValue: _boolValue(warmUpIfPossible),
      requestPermissionIfNeededValue: _boolValue(requestPermissionIfNeeded),
      forceTenantDefaultUnavailableValue:
          _boolValue(forceTenantDefaultUnavailable),
      warmUpTimeoutValue: _durationValue(warmUpTimeout),
      permissionTimeoutValue: _durationValue(permissionTimeout),
    );
  }

  static DomainBooleanValue _boolValue(bool value) {
    final result = DomainBooleanValue(defaultValue: value, isRequired: true);
    result.parse(value.toString());
    return result;
  }

  static UserLocationRepositoryContractDurationValue? _durationValue(
    Duration? value,
  ) {
    if (value == null) {
      return null;
    }
    return UserLocationRepositoryContractDurationValue.fromRaw(
      value,
      defaultValue: value,
    );
  }
}
