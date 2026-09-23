import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_entry.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_scalar.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_profile_type_capability_values.dart';

class TenantAdminProfileTypeCapabilities {
  static final TenantAdminRequiredTextValue _locationPolicyKey =
      TenantAdminRequiredTextValue()..parse('location_policy');
  static final TenantAdminRequiredTextValue _mapPoiKey =
      TenantAdminRequiredTextValue()..parse('is_map_poi_enabled');
  static final TenantAdminRequiredTextValue _physicalHostKey =
      TenantAdminRequiredTextValue()..parse('is_physical_host_enabled');
  static final TenantAdminRequiredTextValue _referenceLocationKey =
      TenantAdminRequiredTextValue()..parse('is_reference_location_enabled');

  TenantAdminProfileTypeCapabilities(
    Iterable<TenantAdminProfileTypeCapabilityEntry> entries,
  ) : entries = List<TenantAdminProfileTypeCapabilityEntry>.unmodifiable(
        entries,
      );

  const TenantAdminProfileTypeCapabilities.empty() : entries = const [];

  final List<TenantAdminProfileTypeCapabilityEntry> entries;

  bool get isEmpty => entries.isEmpty;

  TenantAdminProfileTypeCapabilityValue? valueFor(
    TenantAdminRequiredTextValue keyValue,
  ) {
    for (final entry in entries) {
      if (entry.key == keyValue.value) {
        return entry.configured;
      }
    }
    return null;
  }

  TenantAdminProfileTypeCapabilityValue? effectiveValueFor(
    TenantAdminRequiredTextValue keyValue,
  ) {
    for (final entry in entries) {
      if (entry.key == keyValue.value) {
        return entry.effective;
      }
    }
    return null;
  }

  TenantAdminProfileTypeCapabilities withBooleanValue(
    TenantAdminRequiredTextValue keyValue,
    TenantAdminFlagValue value,
  ) {
    return _withScalar(
      keyValue,
      TenantAdminProfileTypeCapabilityScalar.boolean(value),
    );
  }

  TenantAdminProfileTypeCapabilities withEnumValue(
    TenantAdminRequiredTextValue keyValue,
    TenantAdminRequiredTextValue value,
  ) {
    return _withScalar(
      keyValue,
      TenantAdminProfileTypeCapabilityScalar.enumeration(value),
    );
  }

  TenantAdminProfileTypeCapabilities _withScalar(
    TenantAdminRequiredTextValue keyValue,
    TenantAdminProfileTypeCapabilityScalar nextValue,
  ) {
    var matched = false;
    final nextEntries = entries
        .map((entry) {
          if (entry.key != keyValue.value) {
            return entry;
          }
          matched = true;
          return entry.withConfigured(entry.configured.withScalar(nextValue));
        })
        .toList(growable: false);
    return matched ? TenantAdminProfileTypeCapabilities(nextEntries) : this;
  }

  bool isEnabled(TenantAdminRequiredTextValue keyValue) =>
      valueFor(keyValue)?.booleanValue == true;

  bool isEffectivelyEnabled(TenantAdminRequiredTextValue keyValue) =>
      effectiveValueFor(keyValue)?.booleanValue == true;

  int? parameterValue(
    TenantAdminRequiredTextValue keyValue,
    TenantAdminRequiredTextValue parameterKeyValue,
  ) {
    final configuration = valueFor(keyValue);
    if (configuration == null) {
      return null;
    }
    for (final parameter in configuration.parameters) {
      if (parameter.key == parameterKeyValue.value) {
        return parameter.value;
      }
    }
    return null;
  }

  /// Server-resolved location policy from the latest backend read.
  ///
  /// It stays stale inside an editable draft until the server recomputes it,
  /// so same-form dependency and validation logic must read
  /// [configuredLocationPolicy] instead.
  String get locationPolicy =>
      effectiveValueFor(_locationPolicyKey)?.enumValue ?? '';

  /// Server-resolved location admission; see [locationPolicy] for draft rules.
  bool get allowsLocation =>
      locationPolicy == 'optional' || locationPolicy == 'required';

  /// Server-resolved location requirement; see [locationPolicy] for draft rules.
  bool get requiresLocation => locationPolicy == 'required';

  /// Authoring-time location policy from the configured value.
  ///
  /// This is the value the editable draft mutates through [withEnumValue],
  /// so same-form dependency and validation logic observes in-flight edits
  /// here, without waiting for a server round trip.
  String get configuredLocationPolicy =>
      valueFor(_locationPolicyKey)?.enumValue ?? '';

  /// Authoring-time location admission; see [configuredLocationPolicy].
  bool get configuredAllowsLocation =>
      configuredLocationPolicy == 'optional' ||
      configuredLocationPolicy == 'required';

  /// Authoring-time location requirement; see [configuredLocationPolicy].
  bool get configuredRequiresLocation =>
      configuredLocationPolicy == 'required';

  /// Authoring-time Map POI admission; see [configuredLocationPolicy].
  bool get configuredIsMapPoiEnabled =>
      valueFor(_mapPoiKey)?.booleanValue == true;

  /// Server-resolved Map POI admission; draft consumers read
  /// [configuredIsMapPoiEnabled].
  bool get isMapPoiEnabled => isEffectivelyEnabled(_mapPoiKey);

  /// Server-resolved physical-host admission; draft consumers read
  /// [configuredIsPhysicalHostEnabled].
  bool get isPhysicalHostEnabled => isEffectivelyEnabled(_physicalHostKey);

  /// Server-resolved reference-location admission; draft consumers read
  /// [configuredIsReferenceLocationEnabled].
  bool get isReferenceLocationEnabled =>
      isEffectivelyEnabled(_referenceLocationKey);

  /// Authoring-time physical-host admission; see [configuredLocationPolicy].
  bool get configuredIsPhysicalHostEnabled =>
      valueFor(_physicalHostKey)?.booleanValue == true;

  /// Authoring-time reference-location admission; see [configuredLocationPolicy].
  bool get configuredIsReferenceLocationEnabled =>
      valueFor(_referenceLocationKey)?.booleanValue == true;
}
