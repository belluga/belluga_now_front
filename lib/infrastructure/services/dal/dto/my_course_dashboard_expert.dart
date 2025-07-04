class MyCourseDashboardExpertDTO {
  final String name;
  final String avatarUrl;

  MyCourseDashboardExpertDTO({required this.name, required this.avatarUrl});

  factory MyCourseDashboardExpertDTO.fromMap(Map<String, Object?> map) {
    final _name = map['name'] as String;
    final _avatarUrl = map['avatar_url'] as String;

    return MyCourseDashboardExpertDTO(name: _name, avatarUrl: _avatarUrl);
  }
}
