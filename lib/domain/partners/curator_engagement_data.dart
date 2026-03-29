part of 'engagement_data.dart';

class CuratorEngagementData extends EngagementData {
  final EngagementCountValue articleCountValue;
  final EngagementCountValue docCountValue;

  CuratorEngagementData({
    required this.articleCountValue,
    required this.docCountValue,
  });

  int get articleCount => articleCountValue.value;
  int get docCount => docCountValue.value;
}
