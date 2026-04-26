part of '../tenant_admin_event.dart';

class TenantAdminEventProgrammingItem {
  TenantAdminEventProgrammingItem({
    required this.timeValue,
    TenantAdminOptionalTextValue? titleValue,
    List<TenantAdminAccountProfileIdValue> accountProfileIdValues =
        const <TenantAdminAccountProfileIdValue>[],
    List<TenantAdminAccountProfile> linkedAccountProfiles =
        const <TenantAdminAccountProfile>[],
    this.placeRef,
  })  : titleValue = titleValue ?? TenantAdminOptionalTextValue(),
        accountProfileIdValues =
            List<TenantAdminAccountProfileIdValue>.unmodifiable(
          accountProfileIdValues,
        ),
        linkedAccountProfiles = List<TenantAdminAccountProfile>.unmodifiable(
          linkedAccountProfiles,
        );

  final TenantAdminRequiredTextValue timeValue;
  final TenantAdminOptionalTextValue titleValue;
  final List<TenantAdminAccountProfileIdValue> accountProfileIdValues;
  final List<TenantAdminAccountProfile> linkedAccountProfiles;
  final TenantAdminEventPlaceRef? placeRef;

  String get time => timeValue.value;
  String? get title => titleValue.nullableValue;
  List<TenantAdminAccountProfileIdValue> get accountProfileIds =>
      accountProfileIdValues;
}
