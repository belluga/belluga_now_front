import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';

void main() {
  test('Fetch all events without errors', () async {
    final repo = ScheduleRepository();
    final events = await repo.getAllEvents();
    expect(events.isNotEmpty, true);
  });
}
