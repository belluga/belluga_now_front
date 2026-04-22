part of '../tenant_admin_event.dart';

class TenantAdminEventOccurrence {
  TenantAdminEventOccurrence({
    required this.dateTimeStartValue,
    TenantAdminOptionalDateTimeValue? dateTimeEndValue,
    TenantAdminOptionalTextValue? occurrenceIdValue,
    TenantAdminOptionalTextValue? occurrenceSlugValue,
    List<TenantAdminAccountProfileIdValue> relatedAccountProfileIdValues =
        const <TenantAdminAccountProfileIdValue>[],
    List<TenantAdminAccountProfile> relatedAccountProfiles =
        const <TenantAdminAccountProfile>[],
    this.locationOverride,
    this.placeRef,
    List<TenantAdminEventProgrammingItem> programmingItems =
        const <TenantAdminEventProgrammingItem>[],
  })  : dateTimeEndValue =
            dateTimeEndValue ?? TenantAdminOptionalDateTimeValue(null),
        occurrenceIdValue = occurrenceIdValue ?? TenantAdminOptionalTextValue(),
        occurrenceSlugValue =
            occurrenceSlugValue ?? TenantAdminOptionalTextValue(),
        relatedAccountProfileIdValues =
            List<TenantAdminAccountProfileIdValue>.unmodifiable(
          relatedAccountProfileIdValues,
        ),
        relatedAccountProfiles = List<TenantAdminAccountProfile>.unmodifiable(
          relatedAccountProfiles,
        ),
        programmingItems = List<TenantAdminEventProgrammingItem>.unmodifiable(
          programmingItems,
        );

  final TenantAdminDateTimeValue dateTimeStartValue;
  final TenantAdminOptionalDateTimeValue dateTimeEndValue;
  final TenantAdminOptionalTextValue occurrenceIdValue;
  final TenantAdminOptionalTextValue occurrenceSlugValue;
  final List<TenantAdminAccountProfileIdValue> relatedAccountProfileIdValues;
  final List<TenantAdminAccountProfile> relatedAccountProfiles;
  final TenantAdminEventLocation? locationOverride;
  final TenantAdminEventPlaceRef? placeRef;
  final List<TenantAdminEventProgrammingItem> programmingItems;

  DateTime get dateTimeStart => dateTimeStartValue.value;
  DateTime? get dateTimeEnd => dateTimeEndValue.value;
  String? get occurrenceId => occurrenceIdValue.nullableValue;
  String? get occurrenceSlug => occurrenceSlugValue.nullableValue;
  List<TenantAdminAccountProfileIdValue> get relatedAccountProfileIds =>
      relatedAccountProfileIdValues;
  bool get hasLocationOverride => locationOverride != null;
  int get programmingCount => programmingItems.length;
}
