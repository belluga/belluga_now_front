import 'package:belluga_now/domain/gamification/value_objects/mission_completion_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_progress_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_reward_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_total_required_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class MissionResume {
  MissionResume({
    required this.titleValue,
    required this.descriptionValue,
    required this.progressValue,
    required this.totalRequiredValue,
    required this.rewardValue,
    required this.isCompletedValue,
  });

  final TitleValue titleValue;
  final DescriptionValue descriptionValue;
  final MissionProgressValue progressValue;
  final MissionTotalRequiredValue totalRequiredValue;
  final MissionRewardValue rewardValue;
  final MissionCompletionValue isCompletedValue;

  String get title => titleValue.value;
  String get description => descriptionValue.value;
  int get progress => progressValue.value;
  int get totalRequired => totalRequiredValue.value;
  String get reward => rewardValue.value;
  bool get isCompleted => isCompletedValue.value;

  double get progressPercentage => (progress / totalRequired).clamp(0.0, 1.0);
}
