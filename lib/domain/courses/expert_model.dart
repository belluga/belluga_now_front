import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/expert_name_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/expert_dto.dart';
import 'package:value_objects/domain/value_objects/uri_value.dart';

class ExpertModel {
  final ExpertNameValue name;
  final URIValue avatarUrl;

  ExpertModel({required this.name, required this.avatarUrl});

  factory ExpertModel.fromDTO(ExpertDTO expert) {
    final _avatarUrl = URIValue(
      defaultValue: Uri.parse(
        "https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308",
      ),
    )..tryParse(expert.avatarUrl);

    final _nameValue = ExpertNameValue()..tryParse(expert.name);

    return ExpertModel(name: _nameValue, avatarUrl: _avatarUrl);
  }
}
