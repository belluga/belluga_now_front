import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileGalleryItemDraft {
  const TenantAdminAccountProfileGalleryItemDraft({
    required this.itemId,
    required this.order,
    this.title,
    this.description,
    this.imageUrl,
    this.thumbUrl,
    this.cardUrl,
    this.modalUrl,
    this.uploadFile,
    this.type = TenantAdminAccountProfileGalleryItemType.photo,
    this.youtubeVideoId,
  });

  factory TenantAdminAccountProfileGalleryItemDraft.fromRead(
    TenantAdminAccountProfileGalleryItem item,
  ) {
    return TenantAdminAccountProfileGalleryItemDraft(
      itemId: item.itemId,
      title: item.title,
      description: item.description,
      order: item.order,
      imageUrl: item.imageUrl,
      thumbUrl: item.thumbUrl,
      cardUrl: item.cardUrl,
      modalUrl: item.modalUrl,
      type: item.type,
      youtubeVideoId: item.youtubeVideoId,
    );
  }

  final String itemId;
  final String? title;
  final String? description;
  final int order;
  final String? imageUrl;
  final String? thumbUrl;
  final String? cardUrl;
  final String? modalUrl;
  final XFile? uploadFile;
  final TenantAdminAccountProfileGalleryItemType type;
  final String? youtubeVideoId;

  String? get previewUrl {
    if (type == TenantAdminAccountProfileGalleryItemType.youtube) {
      return 'https://i.ytimg.com/vi/$youtubeVideoId/hqdefault.jpg';
    }
    final image = imageUrl?.trim();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    final card = cardUrl?.trim();
    if (card != null && card.isNotEmpty) {
      return card;
    }
    final modal = modalUrl?.trim();
    if (modal != null && modal.isNotEmpty) {
      return modal;
    }
    // Admin edit previews prefer the canonical/default gallery asset first.
    // Freshly generated thumb variants can lag behind the save response and
    // cause transient 404s during immediate post-save rebuilds.
    final thumb = thumbUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
    return null;
  }

  TenantAdminAccountProfileGalleryItemDraft copyWith({
    String? itemId,
    Object? title = _unset,
    Object? description = _unset,
    int? order,
    Object? imageUrl = _unset,
    Object? thumbUrl = _unset,
    Object? cardUrl = _unset,
    Object? modalUrl = _unset,
    Object? uploadFile = _unset,
    TenantAdminAccountProfileGalleryItemType? type,
    Object? youtubeVideoId = _unset,
  }) {
    return TenantAdminAccountProfileGalleryItemDraft(
      itemId: itemId ?? this.itemId,
      title: title == _unset ? this.title : title as String?,
      description: description == _unset
          ? this.description
          : description as String?,
      order: order ?? this.order,
      imageUrl: imageUrl == _unset ? this.imageUrl : imageUrl as String?,
      thumbUrl: thumbUrl == _unset ? this.thumbUrl : thumbUrl as String?,
      cardUrl: cardUrl == _unset ? this.cardUrl : cardUrl as String?,
      modalUrl: modalUrl == _unset ? this.modalUrl : modalUrl as String?,
      uploadFile: uploadFile == _unset ? this.uploadFile : uploadFile as XFile?,
      type: type ?? this.type,
      youtubeVideoId: youtubeVideoId == _unset
          ? this.youtubeVideoId
          : youtubeVideoId as String?,
    );
  }

  static const Object _unset = Object();
}
