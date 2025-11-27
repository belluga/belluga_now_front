import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_event_hero.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
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
  final _controller = GetIt.I.get<InviteShareScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.invite.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(invite: widget.invite),
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
                          _InviteSummary(invites: sentInvites),
                          const SizedBox(height: 16),
                          if (friendsWithStatus != null)
                            ..._paddedFriends(friendsWithStatus).map(
                              (item) => _FriendCard(
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
                      child: _ShareFooter(invite: widget.invite),
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

  List<_FriendItem> _paddedFriends(
    List<InviteFriendResumeWithStatus> friends,
  ) {
    if (friends.isEmpty) return [];
    final items = <_FriendItem>[
      ...friends.map((f) => _FriendItem(friend: f, isPlaceholder: false)),
    ];
    var idx = 0;
    while (items.length < 20) {
      items.add(
        _FriendItem(friend: friends[idx % friends.length], isPlaceholder: true),
      );
      idx++;
    }
    return items;
  }
}

class _InviteSummary extends StatelessWidget {
  const _InviteSummary({required this.invites});

  final List<SentInviteStatus> invites;

  @override
  Widget build(BuildContext context) {
    final pending =
        invites.where((i) => i.status != InviteStatus.accepted).length;
    final confirmed = invites.length - pending;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OverlappedAvatars(invites: invites),
          const SizedBox(width: 12),
          Text(
            '$pending pendentes | $confirmed aceitos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onInvite,
    required this.isPlaceholder,
  });

  final InviteFriendResume friend;
  final InviteStatus? status;
  final VoidCallback? onInvite;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = friend.matchLabel.isNotEmpty
        ? friend.matchLabel
        : 'Convide para viver o rolê juntos';

    final (label, color, enabled) = _cta(status);
    final disabled = !enabled || isPlaceholder;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(friend.avatarUri.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: disabled ? null : onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    disabled ? theme.colorScheme.surfaceContainerHighest : color,
                foregroundColor:
                    disabled ? theme.colorScheme.onSurface : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, bool) _cta(InviteStatus? status) {
    switch (status) {
      case InviteStatus.accepted:
        return ('Convite Aceito!', Colors.green, false);
      case InviteStatus.pending:
      case InviteStatus.viewed:
        return ('Convidado', Colors.orange, false);
      default:
        return ('Convidar', Colors.blue, true);
    }
  }
}

class _OverlappedAvatars extends StatelessWidget {
  const _OverlappedAvatars({required this.invites});

  final List<SentInviteStatus> invites;

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const _PlusAvatar(0, isEmptySlot: true);
    }

    final cappedCount = invites.length > 3 ? 3 : invites.length;
    final displayInvites = invites.take(cappedCount).toList();
    final remaining = invites.length - cappedCount;

    final items = <Widget>[];
    for (var i = 0; i < displayInvites.length; i++) {
      items.add(Positioned(
        left: i * 18.0,
        child: _InviteAvatar(displayInvites[i]),
      ));
    }

    items.add(Positioned(
      left: cappedCount * 18.0,
      child: remaining > 0
          ? _PlusAvatar(remaining)
          : const _PlusAvatar(0, isEmptySlot: true),
    ));

    final totalItems = cappedCount + 1;
    final width = totalItems * 18.0 + 16.0;

    return SizedBox(
      width: width,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: items,
      ),
    );
  }
}

class _PlusAvatar extends StatelessWidget {
  const _PlusAvatar(this.count, {this.isEmptySlot = false});

  final int count;
  final bool isEmptySlot;

  @override
  Widget build(BuildContext context) {
    final bgColor = isEmptySlot
        ? Colors.grey.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.2);
    final borderColor = Colors.grey.withValues(alpha: 0.5);

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: isEmptySlot
              ? Icon(Icons.person_outline,
                  size: 16, color: Colors.grey.withValues(alpha: 0.8))
              : Text(
                  '+$count',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
        ),
      ),
    );
  }
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar(this.invite);

  final SentInviteStatus invite;

  @override
  Widget build(BuildContext context) {
    final badge = invite.status == InviteStatus.accepted
        ? Icons.check_circle
        : Icons.hourglass_bottom;
    final badgeColor =
        invite.status == InviteStatus.accepted ? Colors.green : Colors.orange;

    final url = invite.friend.avatarUrl;
    final display = invite.friend.displayName;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? Text(
                  display.isNotEmpty ? display[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              badge,
              color: badgeColor,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareFooter extends StatelessWidget {
  const _ShareFooter({required this.invite});

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purple.withValues(alpha: 0.12),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.purple,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartilhar convite',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bora? ${invite.eventName} em ${invite.location}.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              final text =
                  'Bora? ${invite.eventName} em ${invite.location} no dia ${invite.eventDateTime.toLocal()}.\n'
                  'Detalhes: https://belluga.now/invite/${invite.id}';
              SharePlus.instance.share(
                ShareParams(
                  text: text,
                  subject: 'Convite Belluga Now',
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}

class _FriendItem {
  _FriendItem({required this.friend, required this.isPlaceholder});

  final InviteFriendResumeWithStatus friend;
  final bool isPlaceholder;
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.invite});

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = invite.eventDateTime.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          invite.eventName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Dia $day/$month às $hour:$minute',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
