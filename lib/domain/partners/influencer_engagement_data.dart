part of 'engagement_data.dart';

class InfluencerEngagementData extends EngagementData {
  final EngagementCountValue inviteCountValue;

  InfluencerEngagementData({
    required Object inviteCount,
  }) : inviteCountValue = _parseCount(inviteCount);

  int get inviteCount => inviteCountValue.value;

  static EngagementCountValue _parseCount(Object raw) {
    if (raw is EngagementCountValue) {
      return raw;
    }
    final value = EngagementCountValue();
    value.parse(raw.toString());
    return value;
  }
}
