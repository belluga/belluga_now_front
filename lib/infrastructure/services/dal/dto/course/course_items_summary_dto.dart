class CourseItemsSummaryDTO {
  final int total;

  CourseItemsSummaryDTO({
    required this.total,
  });

  factory CourseItemsSummaryDTO.fromJson(Map<String, dynamic> json) {
    return CourseItemsSummaryDTO(
      total: json['total'] as int,
    );
  }
}
