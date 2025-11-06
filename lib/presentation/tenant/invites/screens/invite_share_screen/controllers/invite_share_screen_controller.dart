import 'dart:async';

import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteShareScreenController {
  
  final repository = GetIt.I.get<InvitesRepositoryContract>();

  final friendsSuggestionsStreamValue = StreamValue<List<InviteFriendModel>?>();
  final selectedFriendsSuggestionsStreamValue = StreamValue<List<InviteFriendModel>>(defaultValue: []);

  Future<void> init() async {
    await fetchFriendSuggestions();
  }

  void toggleFriend(InviteFriendModel friend) {
    final _selectedFriends = List<InviteFriendModel>.from(selectedFriendsSuggestionsStreamValue.value);
    if (_selectedFriends.contains(friend)) {
      _selectedFriends.remove(friend);
    } else {
      _selectedFriends.add(friend);
    }
    selectedFriendsSuggestionsStreamValue.addValue(_selectedFriends);
  }

  Future<void> fetchFriendSuggestions() async {
    final _friends = await repository.fetchFriendSuggestions();
    friendsSuggestionsStreamValue.addValue(_friends);
  }

  FutureOr dispose() async {
    friendsSuggestionsStreamValue.dispose();
  }
}
