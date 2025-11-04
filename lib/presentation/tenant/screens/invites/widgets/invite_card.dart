import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    this.isPreview = false,
  });

  final InviteModel invite;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate = dateFormatter.format(invite.eventDateTime.toLocal());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              invite.eventImageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(
                      alpha: isPreview ? 0.6 : 0.8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _Header(
              hostName: invite.hostName,
              formattedDate: formattedDate,
              location: invite.location,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _Footer(
              eventName: invite.eventName,
              message: invite.message,
              tags: invite.tags,
              theme: theme,
              isPreview: isPreview,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.eventName,
    required this.message,
    required this.tags,
    required this.theme,
    required this.isPreview,
  });

  final String eventName;
  final String message;
  final List<String> tags;
  final ThemeData theme;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPreview ? Colors.white60 : Colors.white70,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  shape: const StadiumBorder(),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
