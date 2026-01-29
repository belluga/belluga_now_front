import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';

void main() {
  test('Fetch all events without errors', () async {
    final repo = ScheduleRepository(backend: MockScheduleBackend());
    final events = await repo.getAllEvents();
    expect(events.isNotEmpty, true);
  });
}
