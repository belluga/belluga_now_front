part of 'engagement_data.dart';

typedef ArtistEngagementStatus = String;
typedef ArtistEngagementNextShowAt = DateTime;

class ArtistEngagementData extends EngagementData {
  final ArtistEngagementStatus status;
  final ArtistEngagementNextShowAt? nextShow;

  const ArtistEngagementData({
    required this.status,
    this.nextShow,
  });
}
