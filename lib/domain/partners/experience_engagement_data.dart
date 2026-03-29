part of 'engagement_data.dart';

class ExperienceEngagementData extends EngagementData {
  final EngagementCountValue experienceCountValue;

  ExperienceEngagementData({
    required this.experienceCountValue,
  });

  int get experienceCount => experienceCountValue.value;
}
