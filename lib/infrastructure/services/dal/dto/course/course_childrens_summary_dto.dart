class CourseChildrensSummaryDTO {
  final int total;
  final String? label;

  CourseChildrensSummaryDTO({required this.total, this.label});

  factory CourseChildrensSummaryDTO.fromJson(Map<String, dynamic> json) {
    return CourseChildrensSummaryDTO(
      total: json['total'] as int,
      label: json['label'] as String,
    );
  }

  factory CourseChildrensSummaryDTO.empty() {
    return CourseChildrensSummaryDTO(total: 0);
  }
}
