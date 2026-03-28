part of 'engagement_data.dart';

class CuratorEngagementData extends EngagementData {
  final EngagementCountValue articleCountValue;
  final EngagementCountValue docCountValue;

  CuratorEngagementData({
    required Object articleCount,
    required Object docCount,
  })  : articleCountValue = _parseCount(articleCount),
        docCountValue = _parseCount(docCount);

  int get articleCount => articleCountValue.value;
  int get docCount => docCountValue.value;

  static EngagementCountValue _parseCount(Object raw) {
    if (raw is EngagementCountValue) {
      return raw;
    }
    final value = EngagementCountValue();
    value.parse(raw.toString());
    return value;
  }
}
