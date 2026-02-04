import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart';

mixin ThumbDtoMapper {
  ThumbModel mapThumbDto(ThumbDTO dto) {
    final url = dto.data['url'] as String? ?? '';
    return ThumbModel.fromPrimitives(
      url: url,
      type: dto.type,
    );
  }
}
