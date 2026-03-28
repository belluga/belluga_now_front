part of 'engagement_data.dart';

class VenueEngagementData extends EngagementData {
  final EngagementCountValue presenceCountValue;

  VenueEngagementData({
    required Object presenceCount,
  }) : presenceCountValue = _parseCount(presenceCount);

  int get presenceCount => presenceCountValue.value;

  static EngagementCountValue _parseCount(Object raw) {
    if (raw is EngagementCountValue) {
      return raw;
    }
    final value = EngagementCountValue();
    value.parse(raw.toString());
    return value;
  }
}
