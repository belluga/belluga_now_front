import 'package:intl/intl.dart';

extension EventDateFormatting on DateTime {
  String get monthLabel => DateFormat.MMM().format(this).toUpperCase();

  String get dayLabel => DateFormat.d().format(this);

  String get timeLabel => DateFormat('HH:mm').format(this);
}
