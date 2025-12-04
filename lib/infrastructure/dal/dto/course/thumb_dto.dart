class ThumbDto {
  final String url;
  final String type;

  ThumbDto({
    required this.url,
    required this.type,
  });

  factory ThumbDto.fromJson(Map<String, dynamic> json) {
    return ThumbDto(
      url: json['url'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
    };
  }
}
