import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TelemetryLocationFreshnessValue extends ValueObject<Duration> {
  TelemetryLocationFreshnessValue({
    required super.defaultValue,
    super.isRequired = true,
  });

  @override
  Duration doParse(String? parseValue) {
    final minutes = int.tryParse(parseValue ?? '');
    if (minutes == null || minutes <= 0) {
      throw InvalidValueException();
    }
    return Duration(minutes: minutes);
  }
}
