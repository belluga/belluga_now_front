class CourseItemsSummaryDTO {
  final int total;
  final int totalDurationInSeconds;

  CourseItemsSummaryDTO({
    required this.total,
    required this.totalDurationInSeconds,
  });

  factory CourseItemsSummaryDTO.fromJson(Map<String, dynamic> json) {
    return CourseItemsSummaryDTO(
      total: json['total'] as int,
      totalDurationInSeconds: json['total_duration_in_seconds'] as int,
    );
  }
}
