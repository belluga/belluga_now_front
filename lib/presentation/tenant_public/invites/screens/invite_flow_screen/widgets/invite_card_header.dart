import 'package:flutter/material.dart';

class InviteCardHeader extends StatelessWidget {
  const InviteCardHeader({
    super.key,
    required this.hostName,
    required this.formattedDate,
    required this.location,
  });

  final String hostName;
  final String formattedDate;
  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: const Icon(
            Icons.handshake_outlined,
            size: 16,
          ),
          label: Text(
            hostName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
          shape: const StadiumBorder(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
