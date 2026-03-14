abstract class UserEventsBackendContract {
  Future<Map<String, dynamic>> fetchConfirmedEventIds();

  Future<Map<String, dynamic>> confirmAttendance({
    required String eventId,
    String? occurrenceId,
  });

  Future<Map<String, dynamic>> unconfirmAttendance({
    required String eventId,
    String? occurrenceId,
  });
}

