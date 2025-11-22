import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:flutter/material.dart';

/// Section showing friends who are going to the event
class SocialProofSection extends StatelessWidget {
  const SocialProofSection({
    super.key,
    required this.friendsGoing,
    required this.totalConfirmed,
  });

  final List<EventFriendResume> friendsGoing;
  final int totalConfirmed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (friendsGoing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quem vai',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 40,
                width: _calculateWidth(),
                child: Stack(
                  children: [
                    for (int i = 0; i < friendsGoing.take(5).length; i++)
                      Positioned(
                        left: i * 28.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            backgroundImage: friendsGoing[i].avatarUrl != null
                                ? NetworkImage(friendsGoing[i].avatarUrl!)
                                : null,
                            child: friendsGoing[i].avatarUrl == null
                                ? Text(
                                    friendsGoing[i].displayName.isNotEmpty
                                        ? friendsGoing[i].displayName[0]
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: friendsGoing.first.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (friendsGoing.length > 1) ...[
                        const TextSpan(text: ' e '),
                        TextSpan(
                          text: 'outros ${totalConfirmed - 1} amigos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                      const TextSpan(text: ' vão neste evento'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateWidth() {
    final count = friendsGoing.take(5).length;
    return 40.0 + (count - 1) * 28.0;
  }
}
