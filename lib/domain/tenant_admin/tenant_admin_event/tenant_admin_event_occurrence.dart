part of '../tenant_admin_event.dart';

class TenantAdminEventOccurrence {
  TenantAdminEventOccurrence({
    required this.dateTimeStartValue,
    TenantAdminOptionalDateTimeValue? dateTimeEndValue,
    TenantAdminOptionalTextValue? occurrenceIdValue,
    TenantAdminOptionalTextValue? occurrenceSlugValue,
  })  : dateTimeEndValue =
            dateTimeEndValue ?? const TenantAdminOptionalDateTimeValue(null),
        occurrenceIdValue = occurrenceIdValue ?? TenantAdminOptionalTextValue(),
        occurrenceSlugValue =
            occurrenceSlugValue ?? TenantAdminOptionalTextValue();

  final TenantAdminDateTimeValue dateTimeStartValue;
  final TenantAdminOptionalDateTimeValue dateTimeEndValue;
  final TenantAdminOptionalTextValue occurrenceIdValue;
  final TenantAdminOptionalTextValue occurrenceSlugValue;

  DateTime get dateTimeStart => dateTimeStartValue.value;
  DateTime? get dateTimeEnd => dateTimeEndValue.value;
  String? get occurrenceId => occurrenceIdValue.nullableValue;
  String? get occurrenceSlug => occurrenceSlugValue.nullableValue;
}
