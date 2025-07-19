import 'package:belluga_now/application/extensions/duration_to_format.dart';
import 'package:value_object_pattern/value_object.dart';

class NotePositionValue extends ValueObject<Duration?> {
  NotePositionValue({super.defaultValue, super.isRequired = false});

  @override
  String get valueFormated {
    return value == null ? '' : value!.toFormat("mm:ss");
  }

  @override
  Duration? doParse(String? parseValue) {
    if (parseValue == null || parseValue.isEmpty) {
      return null;
    }

    final parts = parseValue.split(':');

    try {
      // Handle full format from Duration.toString(): "H:MM:SS.mmmmmm"
      if (parts.length == 3) {
        final bool isNegative = parseValue.startsWith('-');
        final String absoluteValue =
            isNegative ? parseValue.substring(1) : parseValue;
        final List<String> hmsParts = absoluteValue.split(':');

        final int hours = int.parse(hmsParts[0]);
        final int minutes = int.parse(hmsParts[1]);

        final List<String> secondParts = hmsParts[2].split('.');
        final int seconds = int.parse(secondParts[0]);
        int microseconds = 0;
        if (secondParts.length == 2) {
          microseconds = int.parse(secondParts[1].padRight(6, '0'));
        }

        final duration = Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          microseconds: microseconds,
        );
        return isNegative ? -duration : duration;
      }
      // Handle simple format: "MM:SS"
      else if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);

        // FIX: Validate that minutes and seconds are within the 0-59 range
        if (minutes < 0 || seconds < 0 || minutes >= 60 || seconds >= 60) {
          throw const FormatException(
            'Invalid "MM:SS" values. Minutes and seconds must be in range [0, 59].',
          );
        }
        return Duration(minutes: minutes, seconds: seconds);
      }
      // If neither format matches, it's invalid.
      else {
        throw const FormatException('Unsupported duration format.');
      }
    } on FormatException catch (e) {
      // Re-throw with more context for easier debugging.
      throw FormatException(
        'Failed to parse "$parseValue": ${e.message}',
        e.source,
      );
    }
  }
}
