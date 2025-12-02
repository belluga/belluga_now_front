import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card_footer.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card_header.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card_inviter_banner.dart';
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
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate = dateFormatter.format(invite.eventDateTime.toLocal());
    final hasInviter = invite.inviters.isNotEmpty ||
        (invite.inviterName?.isNotEmpty ?? false) ||
        invite.additionalInviters.isNotEmpty;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasInviter && isTopOfDeck)
            InviteCardInviterBanner(
              invite: invite,
              isPreview: isPreview,
            ),
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
                    child: InviteCardHeader(
                      hostName: invite.hostName,
                      formattedDate: formattedDate,
                      location: invite.location,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: InviteCardFooter(
                      eventName: invite.eventName,
                      message: invite.message,
                      tags: invite.tags,
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
