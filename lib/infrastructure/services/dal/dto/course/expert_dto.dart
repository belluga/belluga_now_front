class ExpertDTO {
  final String id;
  final String name;
  final String avatarUrl;

  ExpertDTO({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory ExpertDTO.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _name = map['name'] as String;
    final _avatarUrl = map['avatar_url'] as String;

    return ExpertDTO(
      id: _id,
      name: _name,
      avatarUrl: _avatarUrl,
    );
  }
}
