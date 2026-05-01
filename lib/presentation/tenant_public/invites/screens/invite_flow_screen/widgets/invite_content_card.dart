import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_info_row.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/inviter_pill.dart';
import 'package:flutter/material.dart';

class InviteContentCard extends StatelessWidget {
  const InviteContentCard({
    super.key,
    required this.heroImage,
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.host,
    required this.inviter,
    required this.extraInviters,
    required this.onAccept,
    required this.onDecline,
    required this.onRequestAuthentication,
    required this.onViewDetails,
    required this.requiresAuthentication,
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
  final VoidCallback onRequestAuthentication;
  final VoidCallback onViewDetails;
  final bool requiresAuthentication;

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
          BellugaNetworkImage(
            heroImage,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxHeight < 430 || constraints.maxWidth < 280;
              final contentPadding = isCompact ? 12.0 : 16.0;
              final primaryGap = isCompact ? 8.0 : 12.0;
              final secondaryGap = isCompact ? 6.0 : 8.0;
              final buttonPadding = EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 10 : 14,
              );
              final detailsPadding = EdgeInsets.symmetric(
                vertical: isCompact ? 8 : 10,
              );
              final titleStyle = (isCompact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              );
              final content = Column(
                mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InviterPill(
                          inviter: inviter,
                          extraInviters: extraInviters,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: primaryGap),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  SizedBox(height: primaryGap),
                  InviteInfoRow(
                    icon: Icons.event,
                    text: dateLabel,
                    maxLines: 1,
                  ),
                  SizedBox(height: secondaryGap),
                  InviteInfoRow(
                    icon: Icons.place,
                    text: location,
                    maxLines: 1,
                  ),
                  SizedBox(height: secondaryGap),
                  InviteInfoRow(
                    icon: Icons.music_note,
                    text: host,
                    maxLines: 1,
                  ),
                  if (isCompact)
                    SizedBox(height: primaryGap)
                  else
                    const Spacer(),
                  if (requiresAuthentication)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onRequestAuthentication,
                        style: FilledButton.styleFrom(
                          padding: buttonPadding,
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.login),
                        label: Text(
                          'Entre para Aceitar ou Recusar',
                          maxLines: isCompact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDecline,
                            style: OutlinedButton.styleFrom(
                              padding: buttonPadding,
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 10,
                          ),
                          child: Icon(
                            Icons.swipe,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: isCompact ? 18 : 20,
                          ),
                        ),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onAccept,
                            style: FilledButton.styleFrom(
                              padding: buttonPadding,
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(BooraIcons.inviteSolid),
                            label: const Text('Aceitar'),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: isCompact ? 6 : 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onViewDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: detailsPadding,
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
              );

              return Padding(
                padding: EdgeInsets.all(contentPadding),
                child: isCompact
                    ? SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: content,
                      )
                    : content,
              );
            },
          ),
        ],
      ),
    );
  }
}
