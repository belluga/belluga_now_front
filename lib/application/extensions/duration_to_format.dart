extension DurationFormatting on Duration {
  /// Formats the duration into a `HH:mm` string.
  String get toHourMinute {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    return "$hours:$minutes";
  }

  String toFormat(String format) {
    // Use abs() to get positive values for calculations.
    final hours = inHours.abs();
    final minutes = inMinutes.remainder(60).abs();
    final seconds = inSeconds.remainder(60).abs();

    // Add a negative sign back if the duration was negative.
    final sign = isNegative ? '-' : '';

    return sign +
        format.replaceAllMapped(RegExp(r'HH|H|mm|m|ss|s'), (match) {
          final group = match.group(0)!;
          switch (group) {
            case 'HH':
              return hours.toString().padLeft(2, '0');
            case 'mm':
              return minutes.toString().padLeft(2, '0');
            case 'ss':
              return seconds.toString().padLeft(2, '0');
            default:
              return group; // Should not happen with the given RegExp
          }
        });
  }
}
