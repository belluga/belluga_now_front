import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';

class FriendSelectionList extends StatefulWidget {
  const FriendSelectionList({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 120),
  }) : controller = null;

  @visibleForTesting
  const FriendSelectionList.withController(
    this.controller, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 120),
  });

  final InviteShareScreenController? controller;
  final EdgeInsets padding;

  @override
  State<FriendSelectionList> createState() => _FriendSelectionListState();
}

class _FriendSelectionListState extends State<FriendSelectionList> {
  InviteShareScreenController get _controller =>
      widget.controller ?? GetIt.I.get<InviteShareScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<InviteFriendResumeWithStatus>?>(
      streamValue: _controller.friendsSuggestionsStreamValue,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, friendsWithStatus) {
        if (friendsWithStatus == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamValueBuilder<List<InviteFriendResume>>(
          streamValue: _controller.selectedFriendsSuggestionsStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, selectedFriends) {
            return ListView.separated(
              padding: widget.padding,
              itemCount: friendsWithStatus.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = friendsWithStatus[index];
                final friend = item.friend;
                final isSelected = selectedFriends.contains(friend);
                final isInvited = item.isInvited;

                return ListTile(
                  onTap:
                      isInvited ? null : () => _controller.toggleFriend(friend),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(friend.avatarUri.toString()),
                  ),
                  title: Text(friend.name),
                  subtitle: Text(friend.matchLabel),
                  trailing: isInvited
                      ? Chip(
                          label: Text(
                            item.statusLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: item.isAccepted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                        )
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => _controller.toggleFriend(friend),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}
