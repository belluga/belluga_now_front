import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:flutter/material.dart';

class InviteShareAppBarTitle extends StatelessWidget {
  const InviteShareAppBarTitle({
    super.key,
    required this.invite,
  });

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
