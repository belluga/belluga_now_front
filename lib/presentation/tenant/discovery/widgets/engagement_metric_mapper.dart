import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:flutter/material.dart';

class EngagementMetricVM {
  final IconData icon;
  final String value;
  final String tooltip;

  const EngagementMetricVM({
    required this.icon,
    required this.value,
    required this.tooltip,
  });
}

class EngagementMetricMapper {
  static EngagementMetricVM? from(EngagementData data) {
    switch (data) {
      case ArtistEngagementData():
        // Artist live status is rendered elsewhere (badge), skip here.
        return null;
      case VenueEngagementData():
        return EngagementMetricVM(
          icon: Icons.check_circle,
          value: data.presenceCount.toString(),
          tooltip: 'Presenças confirmadas',
        );
      case InfluencerEngagementData():
        // Already shown as acceptedInvites, skip.
        return null;
      case CuratorEngagementData():
        return EngagementMetricVM(
          icon: Icons.explore,
          value: (data.articleCount + data.docCount).toString(),
          tooltip: 'Itens no acervo',
        );
      case ExperienceEngagementData():
        return EngagementMetricVM(
          icon: Icons.local_activity,
          value: data.experienceCount.toString(),
          tooltip: 'Experiências oferecidas',
        );
    }
    return null;
  }
}
