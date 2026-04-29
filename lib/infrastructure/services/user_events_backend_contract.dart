abstract class UserEventsBackendContract {
  Future<Map<String, dynamic>> fetchConfirmedOccurrenceIds();

  Future<Map<String, dynamic>> confirmAttendance({
    required String eventId,
    required String occurrenceId,
  });

  Future<Map<String, dynamic>> unconfirmAttendance({
    required String eventId,
    required String occurrenceId,
  });
}
