part of '../tenant_admin_event.dart';

class TenantAdminEventProgrammingItem {
  TenantAdminEventProgrammingItem({
    TenantAdminOptionalTextValue? timeValue,
    TenantAdminOptionalTextValue? endTimeValue,
    TenantAdminOptionalTextValue? titleValue,
    List<TenantAdminAccountProfileIdValue> accountProfileIdValues =
        const <TenantAdminAccountProfileIdValue>[],
    List<TenantAdminAccountProfile> linkedAccountProfiles =
        const <TenantAdminAccountProfile>[],
    this.locationProfile,
    this.placeRef,
  }) : timeValue = timeValue ?? TenantAdminOptionalTextValue(),
       endTimeValue = endTimeValue ?? TenantAdminOptionalTextValue(),
       titleValue = titleValue ?? TenantAdminOptionalTextValue(),
       accountProfileIdValues =
           List<TenantAdminAccountProfileIdValue>.unmodifiable(
             accountProfileIdValues,
           ),
       linkedAccountProfiles = List<TenantAdminAccountProfile>.unmodifiable(
         linkedAccountProfiles,
       );

  final TenantAdminOptionalTextValue timeValue;
  final TenantAdminOptionalTextValue endTimeValue;
  final TenantAdminOptionalTextValue titleValue;
  final List<TenantAdminAccountProfileIdValue> accountProfileIdValues;
  final List<TenantAdminAccountProfile> linkedAccountProfiles;
  final TenantAdminAccountProfile? locationProfile;
  final TenantAdminEventPlaceRef? placeRef;

  String get time => timeValue.value;
  bool get hasTime => time.trim().isNotEmpty;
  bool get isSequential => !hasTime;
  String? get endTime => endTimeValue.nullableValue;
  String? get title => titleValue.nullableValue;
  List<TenantAdminAccountProfileIdValue> get accountProfileIds =>
      accountProfileIdValues;
}
