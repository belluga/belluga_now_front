import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class VideoDTO {
  final String url;
  final ThumbDTO thumb;

  VideoDTO({required this.url, required this.thumb});

  factory VideoDTO.fromJson(Map<String, dynamic> json) {
    return VideoDTO(
      url: json['url'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
    );
  }
}
