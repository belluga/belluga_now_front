import 'dart:ui';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_content_card.dart';
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
            child: BellugaNetworkImage(
              heroImage,
              fit: BoxFit.cover,
              errorWidget: Container(
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
                              child: InviteContentCard(
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
