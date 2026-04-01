part of 'engagement_data.dart';

class ArtistEngagementData extends EngagementData {
  final EngagementStatusValue statusValue;
  final EngagementNextShowAtValue nextShowValue;

  ArtistEngagementData({
    required this.statusValue,
    EngagementNextShowAtValue? nextShowValue,
  }) : nextShowValue = nextShowValue ?? EngagementNextShowAtValue();

  String get status => statusValue.value;
  DateTime? get nextShow => nextShowValue.value;
}
