import 'package:belluga_now/domain/partners/value_objects/engagement_count_value.dart';
import 'package:belluga_now/domain/partners/value_objects/engagement_next_show_at_value.dart';
import 'package:belluga_now/domain/partners/value_objects/engagement_status_value.dart';

part 'artist_engagement_data.dart';
part 'curator_engagement_data.dart';
part 'experience_engagement_data.dart';
part 'influencer_engagement_data.dart';
part 'venue_engagement_data.dart';

abstract class EngagementData {
  const EngagementData();
}
