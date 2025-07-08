import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class FileDTO {
  final String url;
  final String name;
  final ThumbDTO thumb;

  FileDTO({required this.url, required this.name, required this.thumb});

  factory FileDTO.fromJson(Map<String, dynamic> json) {
    return FileDTO(
      url: json['url'] as String,
      name: json['name'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'name': name, 'thumb': thumb};
  }
}