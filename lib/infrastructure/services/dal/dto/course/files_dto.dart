import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class FileDTO {
  final String url;
  final String title;
  final String? description;
  final ThumbDTO thumb;

  FileDTO({required this.url, required this.title, required this.description, required this.thumb});

  factory FileDTO.fromJson(Map<String, dynamic> json) {
    return FileDTO(
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'title': title, 'description': description, 'thumb': thumb};
  }
}