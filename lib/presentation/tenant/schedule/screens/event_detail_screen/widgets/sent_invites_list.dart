import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/sent_invite_item.dart';
import 'package:flutter/material.dart';

class SentInvitesList extends StatelessWidget {
  const SentInvitesList({
    super.key,
    required this.invites,
    required this.onInviteMore,
  });

  final List<SentInviteStatus> invites;
  final VoidCallback onInviteMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Convites enviados (${invites.length})',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onInviteMore,
                child: const Text('Convidar +'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: invites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SentInviteItem(inviteStatus: invites[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
