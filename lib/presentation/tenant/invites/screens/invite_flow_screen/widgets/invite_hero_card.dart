import 'dart:ui';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/common/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fullscreen invite hero with swipe affordance and CTA buttons.
class InviteHeroCard extends StatelessWidget {
  const InviteHeroCard({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
    required this.onViewDetails,
    required this.onClose,
    required this.remainingCount,
  });

  final InviteModel invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroImage = invite.eventImageUrl;
    final dateLabel = DateFormat('EEE, d MMM - HH:mm', 'pt_BR')
        .format(invite.eventDateTime.toLocal());
    final host = invite.hostName.isNotEmpty ? invite.hostName : 'Belluga Now';
    final location =
        invite.location.isNotEmpty ? invite.location : 'Local a definir';
    final inviter = invite.inviterName ?? 'Um amigo';
    final extraInviters = invite.additionalInviters.length;
    final scrim = Theme.of(context).colorScheme.scrim;

    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Image.network(
              heroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scrim.withValues(alpha: 0.82),
                  scrim.withValues(alpha: 0.45),
                  scrim.withValues(alpha: 0.82),
                ],
                stops: const [0, 0.5, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Fechar',
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SwipeableCard(
                          onSwipeRight: onAccept,
                          onSwipeLeft: onDecline,
                          child: AspectRatio(
                            aspectRatio: 13 / 18,
                            child: _InviteContentCard(
                              heroImage: heroImage,
                              title: invite.eventName,
                              dateLabel: dateLabel,
                              location: location,
                              host: host,
                              inviter: inviter,
                              extraInviters: extraInviters,
                              onAccept: onAccept,
                              onDecline: onDecline,
                              onViewDetails: onViewDetails,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (remainingCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Você tem mais $remainingCount convites',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteContentCard extends StatelessWidget {
  const _InviteContentCard({
    required this.heroImage,
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.host,
    required this.inviter,
    required this.extraInviters,
    required this.onAccept,
    required this.onDecline,
    required this.onViewDetails,
  });

  final String heroImage;
  final String title;
  final String dateLabel;
  final String location;
  final String host;
  final String inviter;
  final int extraInviters;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrim = theme.colorScheme.scrim;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: theme.colorScheme.surfaceContainerHighest),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scrim.withValues(alpha: 0.8),
                  scrim.withValues(alpha: 0.5),
                  scrim.withValues(alpha: 0.9),
                ],
                stops: const [0, 0.45, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InviterPill(
                        inviter: inviter,
                        extraInviters: extraInviters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.event,
                  text: dateLabel,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.place,
                  text: location,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.music_note,
                  text: host,
                  maxLines: 1,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(BooraIcons.invite_solid),
                        label: const Text('Bora!'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onViewDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ver detalhes do evento',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviterPill extends StatelessWidget {
  const _InviterPill({required this.inviter, required this.extraInviters});

  final String inviter;
  final int extraInviters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = extraInviters > 0
        ? '$inviter e +$extraInviters amigos te convidaram.'
        : '$inviter te convidou.';
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.maxLines});

  final IconData icon;
  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
