import 'dart:io';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_entry.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stores arbitrary backend-defined typed values without a local catalog',
    () {
      final capabilities = tenantAdminProfileTypeCapabilitiesFromRaw(
        <String, TenantAdminProfileTypeCapabilityValue>{
          'future_backend_capability':
              tenantAdminProfileTypeCapabilityValueFromRaw(
                value: true,
                parameters: const <String, int>{'limit': 4},
              ),
        },
      );

      final capabilityKey = _text('future_backend_capability');
      expect(capabilities.valueFor(capabilityKey)?.booleanValue, isTrue);
      expect(capabilities.parameterValue(capabilityKey, _text('limit')), 4);
      expect(capabilities.entries.single.key, 'future_backend_capability');
      expect(
        capabilities.entries.single.configured.parameters.single.key,
        'limit',
      );
    },
  );

  test('does not invent missing values or accept undeclared local writes', () {
    final capabilities = TenantAdminProfileTypeCapabilities.empty();

    final missingKey = _text('missing');
    expect(capabilities.valueFor(missingKey), isNull);
    expect(capabilities.parameterValue(missingKey, _text('limit')), isNull);
    expect(
      capabilities.withBooleanValue(missingKey, TenantAdminFlagValue(true)),
      same(capabilities),
    );
  });

  test('configured getters observe in-flight draft edits immediately', () {
    final locationPolicyKey = _text('location_policy');
    final physicalHostKey = _text('is_physical_host_enabled');
    final referenceLocationKey = _text('is_reference_location_enabled');
    final capabilities = TenantAdminProfileTypeCapabilities([
      TenantAdminProfileTypeCapabilityEntry(
        keyValue: locationPolicyKey,
        configured: tenantAdminProfileTypeCapabilityValueFromRaw(
          value: 'disabled',
        ),
        effective: tenantAdminProfileTypeCapabilityValueFromRaw(
          value: 'disabled',
        ),
      ),
      TenantAdminProfileTypeCapabilityEntry(
        keyValue: physicalHostKey,
        configured: tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
        effective: tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
      ),
      TenantAdminProfileTypeCapabilityEntry(
        keyValue: referenceLocationKey,
        configured: tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
        effective: tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
      ),
    ]);

    final edited = capabilities
        .withEnumValue(locationPolicyKey, _text('required'))
        .withBooleanValue(physicalHostKey, TenantAdminFlagValue(true));

    // Server-resolved getters keep the last backend value inside the draft;
    // same-form dependency and validation logic must not rely on them.
    expect(edited.locationPolicy, 'disabled');
    expect(edited.allowsLocation, isFalse);
    expect(edited.requiresLocation, isFalse);
    expect(edited.isPhysicalHostEnabled, isFalse);
    expect(edited.isReferenceLocationEnabled, isFalse);

    // Configured getters observe the in-flight draft edits immediately,
    // without waiting for a server round trip.
    expect(edited.configuredLocationPolicy, 'required');
    expect(edited.configuredAllowsLocation, isTrue);
    expect(edited.configuredRequiresLocation, isTrue);
    expect(edited.configuredIsPhysicalHostEnabled, isTrue);
    expect(edited.configuredIsReferenceLocationEnabled, isFalse);
    expect(edited.configuredIsMapPoiEnabled, isFalse);
  });

  test('keeps defaults and dependency evaluation outside Flutter', () {
    final root = Directory.current.path;
    final capabilities = File(
      '$root/lib/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart',
    ).readAsStringSync();
    final controller = File(
      '$root/lib/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart',
    ).readAsStringSync();
    final form = File(
      '$root/lib/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart',
    ).readAsStringSync();
    final decoder = File(
      '$root/lib/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart',
    ).readAsStringSync();

    expect(capabilities, isNot(contains('fromDefinitions')));
    expect(
      controller,
      isNot(contains("key == 'location_policy' && value == 'disabled'")),
    );
    expect(form, isNot(contains('isLocationDependent')));
    expect(decoder, contains('capability_creation_configuration'));
  });
}

TenantAdminRequiredTextValue _text(String value) =>
    TenantAdminRequiredTextValue()..parse(value);
