import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    this.isPreview = false,
    this.isTopOfDeck = true,
  });

  final InviteModel invite;
  final bool isPreview;
  final bool isTopOfDeck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate = dateFormatter.format(invite.eventDateTime.toLocal());
    final hasInviter = (invite.inviterName?.isNotEmpty ?? false);

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasInviter && isTopOfDeck)
            _InviterBanner(invite: invite, isPreview: isPreview),
          if (hasInviter && isTopOfDeck) const SizedBox(height: 8),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _InviterBanner extends StatelessWidget {
  const _InviterBanner({
    required this.invite,
    required this.isPreview,
  });

  final InviteModel invite;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final name = invite.inviterName;
    if (name == null || name.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final moreCount = invite.additionalInviters.length;
    final avatarUrl = invite.inviterAvatarUrl;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voce foi convidado por $name',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                name,
                style: theme.textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              _Avatar(
                avatarUrl: avatarUrl,
                placeholderText: name.substring(0, 1).toUpperCase(),
              ),
              if (moreCount > 0)
                GestureDetector(
                  onTap: isPreview ? null : () => _showInvitersDialog(context),
                  child: Text(
                    'e mais $moreCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: isPreview
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showInvitersDialog(BuildContext context) async {
    final inviters = _resolveInviters();
    if (inviters.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quem convidou'),
        content: SizedBox(
          width: 320,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              itemCount: inviters.length,
              itemBuilder: (context, index) {
                final inviter = inviters[index];
                return ListTile(
                  leading: _Avatar(
                    avatarUrl: inviter.avatarUrl,
                    placeholderText: inviter.name.isNotEmpty
                        ? inviter.name[0].toUpperCase()
                        : '?',
                  ),
                  title: Text(inviter.name),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<_InviteSummary> _resolveInviters() {
    final inviters = <_InviteSummary>[];
    if (invite.inviterName != null && invite.inviterName!.isNotEmpty) {
      inviters.add(
        _InviteSummary(
          name: invite.inviterName!,
          avatarUrl: invite.inviterAvatarUrl,
        ),
      );
    }

    inviters.addAll(
      invite.additionalInviters.map(
        (name) => _InviteSummary(name: name),
      ),
    );

    return inviters;
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

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.placeholderText,
  });

  final String? avatarUrl;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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

class _InviteSummary {
  _InviteSummary({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
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
