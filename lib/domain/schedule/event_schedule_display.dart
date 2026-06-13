import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventScheduleDisplay {
  EventScheduleDisplay({
    required this.startValue,
    this.endValue,
  });

  final DateTimeValue startValue;
  final DateTimeValue? endValue;

  DateTime get start {
    final value = startValue.value;
    if (value == null) {
      throw StateError('EventScheduleDisplay.start must be defined');
    }
    return TimezoneConverter.utcToLocal(value);
  }

  DateTime? get end {
    final value = endValue?.value;
    if (value == null) {
      return null;
    }
    return TimezoneConverter.utcToLocal(value);
  }

  EventScheduleDisplay withDefaultFallbackEnd() {
    if (end != null) {
      return this;
    }
    final fallbackEndValue = DateTimeValue()
      ..parse(start.add(const Duration(hours: 3)).toIso8601String());
    return EventScheduleDisplay(
      startValue: startValue,
      endValue: fallbackEndValue,
    );
  }

  String get detailLabel {
    final resolvedEnd = end;
    if (resolvedEnd == null) {
      return flyerLabel;
    }
    if (_isSameDate) {
      return '$_startDateLabel · $_startTimeLabel às $_endTimeLabel';
    }
    return '$_startDateLabel · $_startTimeLabel até '
        '$_endDateLabel · $_endTimeLabel';
  }

  String get agendaLabel {
    final resolvedEnd = end;
    if (resolvedEnd == null) {
      return _startTimeLabel;
    }
    if (_isSameDate) {
      return '$_startTimeLabel às $_endTimeLabel';
    }
    return detailLabel;
  }

  String get compactRangeLabel {
    final resolvedEnd = end;
    if (resolvedEnd == null) {
      return _startTimeLabel;
    }
    if (_isSameDate) {
      return '$_startTimeLabel às $_endTimeLabel';
    }
    return '$_startDateLabel · $_startTimeLabel até '
        '$_endDateLabel · $_endTimeLabel';
  }

  String get flyerLabel => '$_startDateLabel · $_startTimeLabel';

  String get startTimeLabel => _startTimeLabel;

  bool get _isSameDate {
    final left = start;
    final right = end;
    if (right == null) {
      return false;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String get _startDateLabel {
    final value = start;
    final weekday = _weekdays[value.weekday - 1];
    final month = _months[value.month - 1];
    return '$weekday, ${value.day} $month';
  }

  String get _endDateLabel {
    final value = end;
    if (value == null) {
      return '';
    }
    final weekday = _weekdays[value.weekday - 1];
    final month = _months[value.month - 1];
    return '$weekday, ${value.day} $month';
  }

  String get _startTimeLabel {
    final value = start;
    if (value.minute == 0) {
      return '${value.hour}h';
    }
    return '${value.hour}h${value.minute.toString().padLeft(2, '0')}';
  }

  String get _endTimeLabel {
    final value = end;
    if (value == null) {
      return '';
    }
    if (value.minute == 0) {
      return '${value.hour}h';
    }
    return '${value.hour}h${value.minute.toString().padLeft(2, '0')}';
  }

  static const _weekdays = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  static const _months = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
}
