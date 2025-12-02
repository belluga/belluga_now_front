class MissionResume {
  MissionResume({
    required this.title,
    required this.description,
    required this.progress,
    required this.totalRequired,
    required this.reward,
    required this.isCompleted,
  });

  final String title;
  final String description;
  final int progress;
  final int totalRequired;
  final String reward;
  final bool isCompleted;

  double get progressPercentage => (progress / totalRequired).clamp(0.0, 1.0);
}
