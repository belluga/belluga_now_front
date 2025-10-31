import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';
import 'package:flutter/material.dart';

class HomeFavorite {
  HomeFavorite({
    required this.titleValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badgeIcon,
    this.isPrimary = false,
  })  : assert(
          imageUriValue != null || assetPathValue != null,
          'Provide either an image or an asset path.',
        ),
        assert(
          imageUriValue == null || assetPathValue == null,
          'Only one of image or asset path can be provided.',
        );

  final TitleValue titleValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final IconData? badgeIcon;
  final bool isPrimary;

  factory HomeFavorite.fromDTO(HomeFavoriteDTO dto) {
    final title = TitleValue()..parse(dto.title);

    ThumbUriValue? imageUri;
    if (dto.imageUrl != null) {
      imageUri = ThumbUriValue(
        defaultValue: Uri.parse(dto.imageUrl!),
        isRequired: true,
      )..parse(dto.imageUrl);
    }

    AssetPathValue? assetPath;
    if (dto.assetPath != null) {
      assetPath = AssetPathValue(
        defaultValue: dto.assetPath!,
        isRequired: true,
      )..parse(dto.assetPath);
    }

    return HomeFavorite(
      titleValue: title,
      imageUriValue: imageUri,
      assetPathValue: assetPath,
      badgeIcon: dto.badgeIconCodePoint != null
          ? IconData(
              dto.badgeIconCodePoint!,
              fontFamily: dto.badgeFontFamily,
              fontPackage: dto.badgeFontPackage,
            )
          : null,
      isPrimary: dto.isPrimary,
    );
  }

  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;
}
