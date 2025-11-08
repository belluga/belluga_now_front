import 'dart:async';

import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteShareScreenController with Disposable {
  InviteShareScreenController({
    InvitesRepositoryContract? repository,
  }) : _repository = repository ?? GetIt.I.get<InvitesRepositoryContract>();

  final InvitesRepositoryContract _repository;

  final friendsSuggestionsStreamValue = StreamValue<List<FriendResume>?>();
  final selectedFriendsSuggestionsStreamValue =
      StreamValue<List<FriendResume>>(defaultValue: []);

  Future<void> init() async {
    await fetchFriendSuggestions();
  }

  void toggleFriend(FriendResume friend) {
    final _selectedFriends =
        List<FriendResume>.from(selectedFriendsSuggestionsStreamValue.value);
    if (_selectedFriends.contains(friend)) {
      _selectedFriends.remove(friend);
    } else {
      _selectedFriends.add(friend);
    }
    selectedFriendsSuggestionsStreamValue.addValue(_selectedFriends);
  }

  Future<void> fetchFriendSuggestions() async {
    final friends = await _repository.fetchFriendResumes();
    friendsSuggestionsStreamValue.addValue(friends);
  }

  @override
  FutureOr<void> onDispose() async {
    friendsSuggestionsStreamValue.dispose();
    selectedFriendsSuggestionsStreamValue.dispose();
  }
}
