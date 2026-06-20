import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class AccountProfileGalleryItem {
  AccountProfileGalleryItem({
    required this.itemIdValue,
    required this.descriptionValue,
    required this.orderValue,
    required this.imageUrlValue,
    required this.thumbUrlValue,
    required this.cardUrlValue,
    required this.modalUrlValue,
  });

  final AccountProfileNestedGroupIdValue itemIdValue;
  final AccountProfileNestedGroupMemberTextValue descriptionValue;
  final AccountProfileNestedGroupOrderValue orderValue;
  final ThumbUriValue imageUrlValue;
  final ThumbUriValue thumbUrlValue;
  final ThumbUriValue cardUrlValue;
  final ThumbUriValue modalUrlValue;

  String get itemId => itemIdValue.value;
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

  String get previewUrl {
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
