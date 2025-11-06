class TeacherDTO {
  final String id;
  final String name;
  final String avatarUrl;
  final bool? highlight;

  TeacherDTO({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.highlight,
  });

  factory TeacherDTO.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _name = map['name'] as String;
    final _avatarUrl = map['avatar_url'] as String;
    final _highlight = map['highlight'] as bool?;

    return TeacherDTO(
      id: _id,
      name: _name,
      avatarUrl: _avatarUrl,
      highlight: _highlight,
    );
  }
}
