import 'package:unifast_portal/domain/courses/thumb_model.dart';
import 'package:unifast_portal/domain/value_objects/description_value.dart';
import 'package:unifast_portal/domain/value_objects/title_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class FileModel {
  final URIValue url;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;

  FileModel({
    required this.url,
    required this.title,
    required this.description,
    required this.thumb,
  });

  factory FileModel.fromDTO(FileDTO fileDTO) {
    final _url = URIValue()..parse(fileDTO.url);
    final _title = TitleValue()..parse(fileDTO.title);
    final _description = DescriptionValue()..tryParse(fileDTO.description);
    final _thumb = ThumbModel.fromDTO(fileDTO.thumb);

    return FileModel(
      url: _url,
      title: _title,
      description: _description,
      thumb: _thumb,
    );
  }
}
