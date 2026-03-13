import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_app_bar_title.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_event_hero.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_footer.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_summary.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteShareScreen extends StatefulWidget {
  const InviteShareScreen({
    super.key,
    required this.invite,
  });

  final InviteModel invite;

  @override
  State<InviteShareScreen> createState() => _InviteShareScreenState();
}

class _InviteShareScreenState extends State<InviteShareScreen> {
  final InviteShareScreenController _controller =
      GetIt.I.get<InviteShareScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.invite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InviteShareAppBarTitle(invite: widget.invite),
      ),
      body: SafeArea(
        child: StreamValueBuilder<List<InviteFriendResumeWithStatus>>(
          streamValue: _controller.friendsSuggestionsStreamValue,
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
                          ..._paddedFriends(friendsWithStatus).map(
                            (item) => InviteShareFriendCard(
                              friend: item.friend.friend,
                              status: item.friend.inviteStatus,
                              onInvite: item.isPlaceholder
                                  ? null
                                  : () => _controller.sendInviteToFriend(
                                        item.friend.friend,
                                      ),
                              isPlaceholder: item.isPlaceholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: StreamValueBuilder<InviteShareCodeResult?>(
                        streamValue: _controller.shareCodeStreamValue,
                        builder: (context, shareCode) {
                          return InviteShareFooter(
                            invite: widget.invite,
                            shareUri: _controller.buildShareUri(shareCode),
                          );
                        },
                      ),
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

  List<_InviteShareFriendItem> _paddedFriends(
    List<InviteFriendResumeWithStatus> friends,
  ) {
    if (friends.isEmpty) return [];
    final items = <_InviteShareFriendItem>[
      ...friends.map(
        (f) => _InviteShareFriendItem(friend: f, isPlaceholder: false),
      ),
    ];
    var idx = 0;
    while (items.length < 20) {
      items.add(
        _InviteShareFriendItem(
          friend: friends[idx % friends.length],
          isPlaceholder: true,
        ),
      );
      idx++;
    }
    return items;
  }
}

class _InviteShareFriendItem {
  _InviteShareFriendItem({required this.friend, required this.isPlaceholder});

  final InviteFriendResumeWithStatus friend;
  final bool isPlaceholder;
}
