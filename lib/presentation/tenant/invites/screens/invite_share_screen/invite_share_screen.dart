import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_app_bar_title.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_event_hero.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_footer.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_summary.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteShareScreen extends StatefulWidget {
  const InviteShareScreen({
    super.key,
    required this.invite,
    required this.controller,
  });

  final InviteModel invite;
  final InviteShareScreenController controller;

  @override
  State<InviteShareScreen> createState() => _InviteShareScreenState();
}

class _InviteShareScreenState extends State<InviteShareScreen> {
  late final InviteShareScreenController _controller = widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.init(widget.invite.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InviteShareAppBarTitle(invite: widget.invite),
      ),
      body: SafeArea(
        child: StreamValueBuilder<List<InviteFriendResumeWithStatus>?>(
          streamValue: _controller.friendsSuggestionsStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, friendsWithStatus) {
            return StreamValueBuilder<List<SentInviteStatus>>(
              streamValue: _controller.sentInvitesStreamValue,
              builder: (context, sentInvites) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        children: [
                          InviteEventHero(invite: widget.invite),
                          const SizedBox(height: 16),
                          InviteShareSummary(invites: sentInvites),
                          const SizedBox(height: 16),
                          if (friendsWithStatus != null)
                            ..._paddedFriends(friendsWithStatus).map(
                              (item) => InviteShareFriendCard(
                                friend: item.friend.friend,
                                status: item.friend.inviteStatus,
                                onInvite: item.isPlaceholder
                                    ? null
                                    : () => _controller.sendInviteToFriend(
                                          item.friend.friend.id,
                                        ),
                                isPlaceholder: item.isPlaceholder,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: InviteShareFooter(invite: widget.invite),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<InviteShareFriendItem> _paddedFriends(
    List<InviteFriendResumeWithStatus> friends,
  ) {
    if (friends.isEmpty) return [];
    final items = <InviteShareFriendItem>[
      ...friends.map(
        (f) => InviteShareFriendItem(friend: f, isPlaceholder: false),
      ),
    ];
    var idx = 0;
    while (items.length < 20) {
      items.add(
        InviteShareFriendItem(
          friend: friends[idx % friends.length],
          isPlaceholder: true,
        ),
      );
      idx++;
    }
    return items;
  }
}

class InviteShareFriendItem {
  InviteShareFriendItem({required this.friend, required this.isPlaceholder});

  final InviteFriendResumeWithStatus friend;
  final bool isPlaceholder;
}
