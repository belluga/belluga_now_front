class ArtistResumeDto {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isHighlight;

  ArtistResumeDto({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isHighlight,
  });

  factory ArtistResumeDto.fromJson(Map<String, dynamic> json) {
    return ArtistResumeDto(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isHighlight: json['is_highlight'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_highlight': isHighlight,
    };
  }
}
