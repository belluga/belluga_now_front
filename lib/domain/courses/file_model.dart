import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/category_name.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:value_objects/domain/value_objects/uri_value.dart';

class FileModel {
  final URIValue url;
  final CategoryNameValue name;
  final ThumbModel thumb;

  FileModel({
    required this.url,
    required this.name,
    required this.thumb,
  });

  factory FileModel.fromDTO(FileDTO fileDTO){

    final _url = URIValue()..parse(fileDTO.url);
    final _name = CategoryNameValue()..parse(fileDTO.name);
    final _thumb = ThumbModel.fromDTO(fileDTO.thumb);

    return FileModel(url: _url, name: _name, thumb: _thumb);
  }
  
}