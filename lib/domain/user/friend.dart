import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class Friend {
  Friend({
    required this.idValue,
    required this.nameValue,
    required this.avatarValue,
    required this.matchLabelValue,
  });

  final FriendIdValue idValue;
  final TitleValue nameValue;
  final FriendAvatarValue avatarValue;
  final FriendMatchLabelValue matchLabelValue;

  String get id => idValue.value;

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
    return other is Friend && other.idValue.value == idValue.value;
  }

  @override
  int get hashCode => idValue.value.hashCode;
}
