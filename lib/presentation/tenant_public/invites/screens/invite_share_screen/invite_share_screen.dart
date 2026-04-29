import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_app_bar_title.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_event_hero.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_footer.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_relation_filter_chips.dart';
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
  late final InviteShareScreenController _controller =
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
        actions: [
          IconButton(
            tooltip: 'Gerenciar grupos',
            onPressed: _openGroupManagement,
            icon: const Icon(Icons.group),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamValueBuilder<List<InviteFriendResumeWithStatus>>(
          streamValue: _controller.friendsSuggestionsStreamValue,
          builder: (context, friendsWithStatus) {
            return StreamValueBuilder<String?>(
              streamValue: _controller.selectedInviteableReasonStreamValue,
              builder: (context, selectedReason) {
                final filteredFriends = _filterFriends(
                  friendsWithStatus,
                  selectedReason,
                );
                final availableReasons = _availableReasons(friendsWithStatus);

                return StreamValueBuilder<List<SentInviteStatus>>(
                  streamValue: _controller.sentInvitesStreamValue,
                  builder: (context, sentInvites) {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            children: [
                              InviteEventHero(invite: widget.invite),
                              const SizedBox(height: 16),
                              InviteShareSummary(invites: sentInvites),
                              const SizedBox(height: 16),
                              StreamValueBuilder<bool>(
                                streamValue: _controller
                                    .isInviteablesRefreshingStreamValue,
                                builder: (context, isRefreshing) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: isRefreshing
                                          ? null
                                          : _controller.refreshFriends,
                                      icon: isRefreshing
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.refresh),
                                      label: Text(
                                        isRefreshing
                                            ? 'Atualizando...'
                                            : 'Atualizar lista de amigos',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              StreamValueBuilder<bool>(
                                streamValue: _controller
                                    .inviteablesRefreshFailedStreamValue,
                                builder: (context, hasRefreshFailed) {
                                  if (!hasRefreshFailed) {
                                    return const SizedBox.shrink();
                                  }

                                  return const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Não foi possível atualizar agora',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              if (availableReasons.isNotEmpty)
                                InviteShareRelationFilterChips(
                                  selectedReason: selectedReason,
                                  availableReasons: availableReasons,
                                  onSelectReason:
                                      _controller.selectInviteableReason,
                                ),
                              if (filteredFriends.isEmpty)
                                Text(
                                  'Nenhum contato convidável para este filtro.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ...filteredFriends.map(
                                (item) => InviteShareFriendCard(
                                  friend: item.friend,
                                  status: item.inviteStatus,
                                  onInvite: () => _controller
                                      .sendInviteToFriend(item.friend),
                                  isPlaceholder: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: StreamValueBuilder<bool>(
                            streamValue:
                                _controller.isShareCodeLoadingStreamValue,
                            builder: (context, isGeneratingShareCode) {
                              return StreamValueBuilder<InviteShareCodeResult?>(
                                streamValue: _controller.shareCodeStreamValue,
                                builder: (context, shareCode) {
                                  return InviteShareFooter(
                                    invite: widget.invite,
                                    shareUri:
                                        _controller.buildShareUri(shareCode),
                                    isGeneratingShareCode:
                                        isGeneratingShareCode,
                                    onRetryShareCode:
                                        _controller.reloadShareCode,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<InviteFriendResumeWithStatus> _filterFriends(
    List<InviteFriendResumeWithStatus> friends,
    String? selectedReason,
  ) {
    final reason = selectedReason?.trim();
    if (reason == null || reason.isEmpty) {
      return friends;
    }
    return friends
        .where((item) => item.friend.inviteableReasons.contains(reason))
        .toList(growable: false);
  }

  List<String> _availableReasons(List<InviteFriendResumeWithStatus> friends) {
    const order = <String>[
      'contact_match',
      'favorite_by_you',
      'favorited_you',
      'friend',
    ];
    final available = <String>{
      for (final item in friends) ...item.friend.inviteableReasons,
    };
    return order.where(available.contains).toList(growable: false);
  }

  void _openGroupManagement() {
    context.router.push(const ContactGroupManagementRoute());
  }
}
