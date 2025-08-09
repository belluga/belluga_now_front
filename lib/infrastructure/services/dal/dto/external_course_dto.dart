import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class ExternalCourseDTO {
  final String id;
  final ThumbDTO thumb;
  final String title;
  final String description;
  final String platformUrl;
  final String? initialPassword;

  ExternalCourseDTO({
    required this.id,
    required this.thumb,
    required this.title,
    required this.description,
    required this.platformUrl,
    this.initialPassword,
  });

  factory ExternalCourseDTO.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _thumb = ThumbDTO.fromJson(map['thumb'] as Map<String, dynamic>);
    final _title = map['title'] as String;
    final _description = map['description'] as String;
    final _platformUrl = map['platform_url'] as String;
    final _initialPassword = map['initial_password'] as String?;

    return ExternalCourseDTO(
      id: _id,
      description: _description,
      platformUrl: _platformUrl,
      thumb: _thumb,
      title: _title,
      initialPassword: _initialPassword,
    );
  }
}
