import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';

class FavoritePreviewPageDTO {
  const FavoritePreviewPageDTO({
    required this.items,
    required this.hasMore,
  });

  final List<FavoritePreviewDTO> items;
  final bool hasMore;
}
