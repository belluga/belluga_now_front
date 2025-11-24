import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:flutter/material.dart';

class YourCrewWidget extends StatelessWidget {
  const YourCrewWidget({
    required this.friendsGoing,
    required this.onInviteFriends,
    super.key,
  });

  final List<EventFriendResume> friendsGoing;
  final VoidCallback onInviteFriends;

  @override
  Widget build(BuildContext context) {
    final displayedFriends = friendsGoing.take(3).toList();
    final hasFriends = displayedFriends.isNotEmpty;
    final showTitle = !hasFriends;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showTitle) ...[
            const Text(
              'Quem vai com você?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...displayedFriends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FriendAvatar(name: friend.displayName, url: friend.avatarUrl),
                ),
              ),
              if (hasFriends)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ActionAvatar(
                    onTap: onInviteFriends,
                    icon: Icons.rocket_launch,
                    backgroundColor: Colors.purple.withValues(alpha: 0.15),
                    iconColor: Colors.purple,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ActionAvatar(
                    onTap: onInviteFriends,
                    icon: Icons.add,
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    iconColor: Colors.blue,
                  ),
                ),
                _BoraButton(onTap: onInviteFriends),
              ],
            ],
          ),
          if (hasFriends) ...[
            const SizedBox(height: 6),
            Text(
              _buildSummary(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _buildSummary() {
    final last = friendsGoing.last.displayName;
    final othersCount = friendsGoing.length - 1;
    if (othersCount <= 0) {
      return '$last aceitou seu convite.';
    }
    return '$last e mais $othersCount aceitaram seu convite.';
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
          child: (url == null || url!.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoraButton extends StatelessWidget {
  const _BoraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      icon: const Icon(Icons.rocket_launch, size: 18),
      label: const Text(
        'BORA? Agitar a galera!',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _ActionAvatar extends StatelessWidget {
  const _ActionAvatar({
    required this.onTap,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: backgroundColor,
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
