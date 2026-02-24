import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/quick_action_button.dart';
import 'package:flutter/material.dart';

/// Grid of quick actions for confirmed events
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.onFavoriteArtists,
    required this.onFavoriteVenue,
    required this.onSetReminder,
    required this.onInviteFriends,
  });

  final VoidCallback onFavoriteArtists;
  final VoidCallback onFavoriteVenue;
  final VoidCallback onSetReminder;
  final VoidCallback onInviteFriends;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          QuickActionButton(
            icon: Icons.star_outline,
            label: 'Favoritar\nArtistas',
            onTap: onFavoriteArtists,
          ),
          QuickActionButton(
            icon: Icons.place_outlined,
            label: 'Salvar\nLocal',
            onTap: onFavoriteVenue,
          ),
          QuickActionButton(
            icon: Icons.notifications_outlined,
            label: 'Definir\nLembrete',
            onTap: onSetReminder,
          ),
          QuickActionButton(
            icon: Icons.share_outlined,
            label: 'Convidar\nAmigos',
            onTap: onInviteFriends,
            isHighlight: true,
          ),
        ],
      ),
    );
  }
}
