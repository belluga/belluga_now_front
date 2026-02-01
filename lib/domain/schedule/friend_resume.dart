import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';

/// Lightweight friend projection for event social proof and invite tracking
class EventFriendResume {
  EventFriendResume({
    required this.idValue,
    required this.displayNameValue,
    required this.avatarUrlValue,
  });

  final UserIdValue idValue;
  final UserDisplayNameValue displayNameValue;
  final UserAvatarValue avatarUrlValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarUrl => avatarUrlValue.value?.toString();

  factory EventFriendResume.fromPrimitives({
    required String id,
    required String displayName,
    String? avatarUrl,
  }) {
    return EventFriendResume(
      idValue: UserIdValue()..parse(id),
      displayNameValue: UserDisplayNameValue()..parse(displayName),
      avatarUrlValue: UserAvatarValue()..parse(avatarUrl ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
}
