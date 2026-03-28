part of 'engagement_data.dart';

class ExperienceEngagementData extends EngagementData {
  final EngagementCountValue experienceCountValue;

  ExperienceEngagementData({
    required Object experienceCount,
  }) : experienceCountValue = _parseCount(experienceCount);

  int get experienceCount => experienceCountValue.value;

  static EngagementCountValue _parseCount(Object raw) {
    if (raw is EngagementCountValue) {
      return raw;
    }
    final value = EngagementCountValue();
    value.parse(raw.toString());
    return value;
  }
}
