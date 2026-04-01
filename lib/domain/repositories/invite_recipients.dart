import 'dart:collection';

import 'package:belluga_now/domain/schedule/friend_resume.dart';

class InviteRecipients extends IterableBase<EventFriendResume> {
  const InviteRecipients.empty() : _items = const <EventFriendResume>[];

  InviteRecipients() : _items = <EventFriendResume>[];

  final List<EventFriendResume> _items;

  void add(EventFriendResume item) {
    _items.add(item);
  }

  List<EventFriendResume> get items =>
      List<EventFriendResume>.unmodifiable(_items);
  @override
  bool get isEmpty => _items.isEmpty;
  @override
  bool get isNotEmpty => _items.isNotEmpty;
  @override
  int get length => _items.length;

  @override
  Iterator<EventFriendResume> get iterator => _items.iterator;
}
