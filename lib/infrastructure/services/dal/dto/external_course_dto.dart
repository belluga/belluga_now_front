class ExternalCourseDTO {
  final String id;
  final String thumUrl;
  final String title;
  final String description;
  final String platformUrl;
  final String? initialPassword;

  ExternalCourseDTO({
    required this.id,
    required this.thumUrl,
    required this.title,
    required this.description,
    required this.platformUrl,
    this.initialPassword,
  });

  factory ExternalCourseDTO.fromMap(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _thumb = map['thumb_url'] as String;
    final _title = map['title'] as String;
    final _description = map['description'] as String;
    final _platformUrl = map['platform_url'] as String;
    final _initialPassword = map['initial_password'] as String?;

    return ExternalCourseDTO(
      id: _id,
      description: _description,
      platformUrl: _platformUrl,
      thumUrl: _thumb,
      title: _title,
      initialPassword: _initialPassword,
    );
  }
}
