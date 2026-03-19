import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class MockFriendsDatabase {
  MockFriendsDatabase();

  List<Friend> get friends => _friends;

  static final List<Friend> _friends = [
    Friend(
      idValue: FriendIdValue()..parse('carol-viajante'),
      nameValue: TitleValue()..parse('Carol Viajante'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Vocês foram a 4 experiencias de oceano juntos'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('leo-fotografo'),
      nameValue: TitleValue()..parse('Leo Fotografo'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Amigo destaque em fotografia submarina'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('bia-surfer'),
      nameValue: TitleValue()..parse('Bia Surfer'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=400&q=80'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Curte remadas noturnas e aulas de SUP'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('igor-tech'),
      nameValue: TitleValue()..parse('Igor Tech'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Sempre topa experiencias com storytelling'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('mila-yogi'),
      nameValue: TitleValue()..parse('Mila Yogi'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Parceira dos retiros de bem-estar'),
    ),
  ];
}
