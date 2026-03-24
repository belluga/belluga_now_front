part of 'engagement_data.dart';

typedef InfluencerInviteCount = int;

class InfluencerEngagementData extends EngagementData {
  final InfluencerInviteCount inviteCount;

  const InfluencerEngagementData({
    required this.inviteCount,
  });
}
