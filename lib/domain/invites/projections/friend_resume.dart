import 'package:belluga_now/domain/user/friend.dart';

class FriendResume {
  FriendResume({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.matchLabel,
  });

  final String id;
  final String name;
  final Uri avatarUrl;
  final String matchLabel;

  factory FriendResume.fromFriend(Friend friend) {
    return FriendResume(
      id: friend.id,
      name: friend.name,
      avatarUrl: friend.avatarUri,
      matchLabel: friend.matchLabel,
    );
  }
}
