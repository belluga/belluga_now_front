part of 'engagement_data.dart';

class VenueEngagementData extends EngagementData {
  final EngagementCountValue presenceCountValue;

  VenueEngagementData({
    required this.presenceCountValue,
  });

  int get presenceCount => presenceCountValue.value;
}
