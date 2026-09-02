import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_gallery_player_aspect_ratio_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_gallery/belluga_gallery.dart';

enum AccountProfileGalleryItemType { photo, youtube }

class AccountProfileGalleryItem {
  AccountProfileGalleryItem({
    required this.itemIdValue,
    required this.descriptionValue,
    required this.orderValue,
    required this.imageUrlValue,
    required this.thumbUrlValue,
    required this.cardUrlValue,
    required this.modalUrlValue,
    this.type = AccountProfileGalleryItemType.photo,
    AccountProfileNestedGroupMemberTextValue? titleValue,
    AccountProfileNestedGroupMemberTextValue? youtubeVideoIdValue,
    AccountProfileGalleryPlayerAspectRatioValue? playerAspectRatioValue,
  }) : titleValue = titleValue ?? AccountProfileNestedGroupMemberTextValue(),
       youtubeVideoIdValue =
           youtubeVideoIdValue ?? AccountProfileNestedGroupMemberTextValue(),
       playerAspectRatioValue =
           playerAspectRatioValue ??
           AccountProfileGalleryPlayerAspectRatioValue();

  final AccountProfileNestedGroupIdValue itemIdValue;
  final AccountProfileNestedGroupMemberTextValue titleValue;
  final AccountProfileNestedGroupMemberTextValue descriptionValue;
  final AccountProfileNestedGroupOrderValue orderValue;
  final ThumbUriValue imageUrlValue;
  final ThumbUriValue thumbUrlValue;
  final ThumbUriValue cardUrlValue;
  final ThumbUriValue modalUrlValue;
  final AccountProfileGalleryItemType type;
  final AccountProfileNestedGroupMemberTextValue youtubeVideoIdValue;
  final AccountProfileGalleryPlayerAspectRatioValue playerAspectRatioValue;

  String get itemId => itemIdValue.value;
  String? get title {
    final normalized = titleValue.value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? get description {
    final normalized = descriptionValue.value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int get order => orderValue.value;
  String get imageUrl => imageUrlValue.value.toString();
  String get thumbUrl => thumbUrlValue.value.toString();
  String get cardUrl => cardUrlValue.value.toString();
  String get modalUrl => modalUrlValue.value.toString();
  String? get youtubeVideoId {
    final normalized = youtubeVideoIdValue.value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  double get playerAspectRatio => playerAspectRatioValue.value;

  GalleryItem toGalleryItem() => switch (type) {
    AccountProfileGalleryItemType.photo => GalleryPhoto(
      itemId: itemId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      thumbUrl: thumbUrl,
      cardUrl: cardUrl,
      modalUrl: modalUrl,
    ),
    AccountProfileGalleryItemType.youtube => GalleryYoutubePlayer(
      itemId: itemId,
      title: title,
      description: description,
      youtubeVideoId: youtubeVideoId ?? '',
      playerAspectRatio: playerAspectRatio,
    ),
  };

  String get previewUrl {
    if (type == AccountProfileGalleryItemType.youtube) {
      return (toGalleryItem() as GalleryYoutubePlayer).thumbnailUrl;
    }
    final image = imageUrl.trim();
    if (image.isNotEmpty) {
      return image;
    }
    final card = cardUrl.trim();
    if (card.isNotEmpty) {
      return card;
    }
    final modal = modalUrl.trim();
    if (modal.isNotEmpty) {
      return modal;
    }
    return thumbUrl.trim();
  }
}
