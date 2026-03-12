part of 'engagement_data.dart';

class ArtistEngagementData extends EngagementData {
  final String status;
  final DateTime? nextShow;

  const ArtistEngagementData({
    required this.status,
    this.nextShow,
  });
}
