import 'package:flutter/material.dart';

class InviteSummaryAvatar extends StatelessWidget {
  const InviteSummaryAvatar({
    super.key,
    required this.avatarUrl,
    required this.placeholderText,
    this.radius = 24,
  });

  final String? avatarUrl;
  final String placeholderText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      child: avatarUrl == null
          ? Text(
              placeholderText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }
}
