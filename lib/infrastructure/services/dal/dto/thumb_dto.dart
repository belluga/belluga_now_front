class ThumbDTO {
  String type;
  Map<String, dynamic> data;

  ThumbDTO({required this.type, required this.data});

  factory ThumbDTO.fromJson(Map<String, dynamic> json) {
    return ThumbDTO(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}
