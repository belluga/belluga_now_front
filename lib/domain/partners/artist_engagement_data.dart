part of 'engagement_data.dart';

class ArtistEngagementData extends EngagementData {
  final EngagementStatusValue statusValue;
  final EngagementNextShowAtValue nextShowValue;

  ArtistEngagementData({
    required Object status,
    Object? nextShow,
  })  : statusValue = _parseStatus(status),
        nextShowValue = _parseNextShow(nextShow);

  String get status => statusValue.value;
  DateTime? get nextShow => nextShowValue.value;

  static EngagementStatusValue _parseStatus(Object raw) {
    if (raw is EngagementStatusValue) {
      return raw;
    }
    final value = EngagementStatusValue();
    value.parse(raw.toString());
    return value;
  }

  static EngagementNextShowAtValue _parseNextShow(Object? raw) {
    if (raw is EngagementNextShowAtValue) {
      return raw;
    }
    final value = EngagementNextShowAtValue();
    if (raw is DateTime) {
      value.parse(raw.toIso8601String());
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }
}
