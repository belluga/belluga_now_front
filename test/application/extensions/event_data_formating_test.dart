import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timeLabel formats provided datetime without timezone conversion', () {
    final value = DateTime.utc(2026, 3, 29, 23, 15);

    expect(value.timeLabel, '23:15');
  });
}
