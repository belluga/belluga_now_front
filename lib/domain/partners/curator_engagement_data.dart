part of 'engagement_data.dart';

typedef CuratorArticleCount = int;
typedef CuratorDocCount = int;

class CuratorEngagementData extends EngagementData {
  final CuratorArticleCount articleCount;
  final CuratorDocCount docCount;

  const CuratorEngagementData({
    required this.articleCount,
    required this.docCount,
  });
}
