import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_key.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_catalog.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminProfileTypeCapabilityStateValue {
  TenantAdminProfileTypeCapabilityStateValue([Map<String, dynamic>? rawMap])
      : _value = Map<String, dynamic>.unmodifiable(
          rawMap == null
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(rawMap),
        );

  final Map<String, dynamic> _value;

  bool containsCapability(TenantAdminProfileTypeCapabilityKey key) {
    return _value.containsKey(key.apiValue);
  }

  TenantAdminFlagValue flagValue(
    TenantAdminProfileTypeCapabilityKey key, {
    TenantAdminFlagValue? defaultValue,
  }) {
    if (!containsCapability(key)) {
      return defaultValue ?? TenantAdminFlagValue(false);
    }
    return TenantAdminFlagValue(_parseBool(_value[key.apiValue]));
  }

  TenantAdminProfileTypeCapabilityStateValue withCapability(
    TenantAdminProfileTypeCapabilityKey key,
    TenantAdminFlagValue flagValue,
  ) {
    final next = Map<String, dynamic>.from(_value);
    next[key.apiValue] = flagValue.value;
    return TenantAdminProfileTypeCapabilityStateValue(next);
  }

  TenantAdminProfileTypeCapabilityStateValue normalized({
    TenantAdminProfileTypeCapabilityStateValue? currentCapabilities,
  }) {
    var normalized = TenantAdminProfileTypeCapabilityStateValue();

    for (final key in TenantAdminProfileTypeCapabilityCatalog.keys) {
      final flagValue = containsCapability(key)
          ? this.flagValue(key)
          : currentCapabilities?.flagValue(
                key,
                defaultValue:
                    TenantAdminProfileTypeCapabilityCatalog.defaultValueFor(
                  key,
                ),
              ) ??
              TenantAdminProfileTypeCapabilityCatalog.defaultValueFor(key);

      normalized = normalized.withCapability(key, flagValue);
    }

    for (final key in TenantAdminProfileTypeCapabilityCatalog.keys) {
      final enabled = normalized.flagValue(key).value;
      final requirementsSatisfied =
          TenantAdminProfileTypeCapabilityCatalog.requiredKeysFor(key)
              .every((requiredKey) => normalized.flagValue(requiredKey).value);
      if (enabled && !requirementsSatisfied) {
        normalized =
            normalized.withCapability(key, TenantAdminFlagValue(false));
      }
    }

    return normalized;
  }

  Map<String, dynamic> toJson() => _value;

  static bool _parseBool(Object? value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }
}
