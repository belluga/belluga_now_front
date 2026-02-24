import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:flutter/material.dart';

class SentInviteStatusBadge extends StatelessWidget {
  const SentInviteStatusBadge({
    super.key,
    required this.status,
    required this.size,
  });

  final InviteStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    Color color;
    Color backgroundColor = colorScheme.surface;

    switch (status) {
      case InviteStatus.accepted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case InviteStatus.declined:
        icon = Icons.cancel;
        color = colorScheme.error;
        break;
      case InviteStatus.viewed:
        icon = Icons.visibility;
        color = Colors.blue;
        break;
      case InviteStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        icon,
        size: size * 0.4,
        color: color,
      ),
    );
  }
}
