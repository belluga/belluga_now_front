part of 'engagement_data.dart';

typedef VenuePresenceCount = int;

class VenueEngagementData extends EngagementData {
  final VenuePresenceCount presenceCount;

  const VenueEngagementData({
    required this.presenceCount,
  });
}
