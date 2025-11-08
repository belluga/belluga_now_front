import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class Friend {
  Friend({
    required this.id,
    required this.nameValue,
    required this.avatarValue,
    required this.matchLabelValue,
  }) : assert(id.trim().isNotEmpty, 'Friend id cannot be empty');

  final String id;
  final TitleValue nameValue;
  final FriendAvatarValue avatarValue;
  final FriendMatchLabelValue matchLabelValue;

  String get name => nameValue.value;
  Uri get avatarUri {
    final uri = avatarValue.value;
    if (uri == null) {
      throw StateError('Friend avatar must not be null');
    }
    return uri;
  }
  String get matchLabel => matchLabelValue.value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friend && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
