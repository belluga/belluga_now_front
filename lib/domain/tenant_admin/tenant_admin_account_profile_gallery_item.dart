import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_gallery/belluga_gallery.dart';

enum TenantAdminAccountProfileGalleryItemType { photo, youtube }

class TenantAdminAccountProfileGalleryItem {
  TenantAdminAccountProfileGalleryItem({
    required this.itemIdValue,
    required this.descriptionValue,
    required this.orderValue,
    required this.imageUrlValue,
    required this.thumbUrlValue,
    required this.cardUrlValue,
    required this.modalUrlValue,
    this.type = TenantAdminAccountProfileGalleryItemType.photo,
    TenantAdminOptionalTextValue? youtubeVideoIdValue,
  }) : youtubeVideoIdValue =
           youtubeVideoIdValue ?? TenantAdminOptionalTextValue();

  final TenantAdminNestedProfileGroupTextValue itemIdValue;
  final TenantAdminOptionalTextValue descriptionValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final TenantAdminOptionalUrlValue imageUrlValue;
  final TenantAdminOptionalUrlValue thumbUrlValue;
  final TenantAdminOptionalUrlValue cardUrlValue;
  final TenantAdminOptionalUrlValue modalUrlValue;
  final TenantAdminAccountProfileGalleryItemType type;
  final TenantAdminOptionalTextValue youtubeVideoIdValue;

  String get itemId => itemIdValue.value;
  String? get description => descriptionValue.nullableValue;
  int get order => orderValue.value;
  String get imageUrl => imageUrlValue.nullableValue ?? '';
  String get thumbUrl => thumbUrlValue.nullableValue ?? '';
  String get cardUrl => cardUrlValue.nullableValue ?? '';
  String get modalUrl => modalUrlValue.nullableValue ?? '';
  String? get youtubeVideoId => youtubeVideoIdValue.nullableValue;

  GalleryItem toGalleryItem() => switch (type) {
    TenantAdminAccountProfileGalleryItemType.photo => GalleryPhoto(
      itemId: itemId,
      description: description,
      imageUrl: imageUrl,
      thumbUrl: thumbUrl,
      cardUrl: cardUrl,
      modalUrl: modalUrl,
    ),
    TenantAdminAccountProfileGalleryItemType.youtube => GalleryYoutubePlayer(
      itemId: itemId,
      description: description,
      youtubeVideoId: youtubeVideoId ?? '',
    ),
  };

  String get previewUrl {
    if (type == TenantAdminAccountProfileGalleryItemType.youtube) {
      return (toGalleryItem() as GalleryYoutubePlayer).thumbnailUrl;
    }
    if (thumbUrl.trim().isNotEmpty) {
      return thumbUrl;
    }
    if (cardUrl.trim().isNotEmpty) {
      return cardUrl;
    }
    if (imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }
    return modalUrl;
  }
}
