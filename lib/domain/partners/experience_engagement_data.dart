part of 'engagement_data.dart';

typedef ExperienceCount = int;

class ExperienceEngagementData extends EngagementData {
  final ExperienceCount experienceCount;

  const ExperienceEngagementData({
    required this.experienceCount,
  });
}
