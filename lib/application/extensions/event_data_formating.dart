import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:intl/intl.dart';

extension EventDateFormatting on DateTime {
  DateTime get _localValue => TimezoneConverter.utcToLocal(this);

  String get monthLabel => DateFormat.MMM().format(_localValue).toUpperCase();

  String get dayLabel => DateFormat.d().format(_localValue);

  String get timeLabel => DateFormat('HH:mm').format(_localValue);
}
