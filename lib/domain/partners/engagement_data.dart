abstract class EngagementData {
  const EngagementData();
}

class ArtistEngagementData extends EngagementData {
  final String status; // e.g., "TOCANDO AGORA"
  final DateTime? nextShow;

  const ArtistEngagementData({
    required this.status,
    this.nextShow,
  });
}

class VenueEngagementData extends EngagementData {
  final int presenceCount;

  const VenueEngagementData({
    required this.presenceCount,
  });
}

class InfluencerEngagementData extends EngagementData {
  final int inviteCount;

  const InfluencerEngagementData({
    required this.inviteCount,
  });
}

class CuratorEngagementData extends EngagementData {
  final int articleCount;
  final int docCount;

  const CuratorEngagementData({
    required this.articleCount,
    required this.docCount,
  });
}

class ExperienceEngagementData extends EngagementData {
  final int experienceCount;

  const ExperienceEngagementData({
    required this.experienceCount,
  });
}
