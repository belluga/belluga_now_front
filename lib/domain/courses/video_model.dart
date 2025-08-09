import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/video_dto.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class VideoModel {
  final URIValue url;
  final ThumbModel thumb;

  VideoModel({required this.url, required this.thumb});

  factory VideoModel.fromDTO(VideoDTO video) {
    final _url = URIValue()..parse(video.url);
    final _thumb = ThumbModel.fromDTO(video.thumb);

    return VideoModel(url: _url, thumb: _thumb);
  }
}
