part of '../tenant_admin_event.dart';

class TenantAdminEventOccurrence {
  const TenantAdminEventOccurrence({
    required this.dateTimeStart,
    this.dateTimeEnd,
    this.occurrenceId,
    this.occurrenceSlug,
  });

  final DateTime dateTimeStart;
  final DateTime? dateTimeEnd;
  final String? occurrenceId;
  final String? occurrenceSlug;
}
