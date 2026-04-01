part of 'engagement_data.dart';

class InfluencerEngagementData extends EngagementData {
  final EngagementCountValue inviteCountValue;

  InfluencerEngagementData({
    required this.inviteCountValue,
  });

  int get inviteCount => inviteCountValue.value;
}
