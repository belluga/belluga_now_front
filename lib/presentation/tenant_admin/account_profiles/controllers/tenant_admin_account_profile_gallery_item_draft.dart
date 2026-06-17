import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileGalleryItemDraft {
  const TenantAdminAccountProfileGalleryItemDraft({
    required this.itemId,
    required this.order,
    this.description,
    this.imageUrl,
    this.thumbUrl,
    this.cardUrl,
    this.modalUrl,
    this.uploadFile,
  });

  factory TenantAdminAccountProfileGalleryItemDraft.fromRead(
    TenantAdminAccountProfileGalleryItem item,
  ) {
    return TenantAdminAccountProfileGalleryItemDraft(
      itemId: item.itemId,
      description: item.description,
      order: item.order,
      imageUrl: item.imageUrl,
      thumbUrl: item.thumbUrl,
      cardUrl: item.cardUrl,
      modalUrl: item.modalUrl,
    );
  }

  final String itemId;
  final String? description;
  final int order;
  final String? imageUrl;
  final String? thumbUrl;
  final String? cardUrl;
  final String? modalUrl;
  final XFile? uploadFile;

  String? get previewUrl {
    final thumb = thumbUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
    final card = cardUrl?.trim();
    if (card != null && card.isNotEmpty) {
      return card;
    }
    final image = imageUrl?.trim();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    final modal = modalUrl?.trim();
    if (modal != null && modal.isNotEmpty) {
      return modal;
    }
    return null;
  }

  TenantAdminAccountProfileGalleryItemDraft copyWith({
    String? itemId,
    Object? description = _unset,
    int? order,
    Object? imageUrl = _unset,
    Object? thumbUrl = _unset,
    Object? cardUrl = _unset,
    Object? modalUrl = _unset,
    Object? uploadFile = _unset,
  }) {
    return TenantAdminAccountProfileGalleryItemDraft(
      itemId: itemId ?? this.itemId,
      description: description == _unset ? this.description : description as String?,
      order: order ?? this.order,
      imageUrl: imageUrl == _unset ? this.imageUrl : imageUrl as String?,
      thumbUrl: thumbUrl == _unset ? this.thumbUrl : thumbUrl as String?,
      cardUrl: cardUrl == _unset ? this.cardUrl : cardUrl as String?,
      modalUrl: modalUrl == _unset ? this.modalUrl : modalUrl as String?,
      uploadFile: uploadFile == _unset ? this.uploadFile : uploadFile as XFile?,
    );
  }

  static const Object _unset = Object();
}
