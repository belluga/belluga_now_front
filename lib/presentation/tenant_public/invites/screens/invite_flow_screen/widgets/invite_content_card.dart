import 'package:belluga_now/application/schedule/event_related_profile_group_summary.dart';
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
    required this.showHost,
    required this.inviter,
    required this.extraInviters,
    required this.participantGroups,
    required this.onViewDetails,
  });

  final String heroImage;
  final String title;
  final String dateLabel;
  final String location;
  final String host;
  final bool showHost;
  final String inviter;
  final int extraInviters;
  final List<EventRelatedProfileGroupSummary> participantGroups;
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
                  if (showHost) ...[
                    SizedBox(height: secondaryGap),
                    InviteInfoRow(
                      icon: Icons.storefront_outlined,
                      text: host,
                      maxLines: 1,
                    ),
                  ],
                  if (participantGroups.isNotEmpty) ...[
                    SizedBox(height: secondaryGap),
                    Text(
                      'Participantes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: secondaryGap),
                    ...participantGroups.take(isCompact ? 2 : 3).map(
                          (group) => Padding(
                            padding: EdgeInsets.only(bottom: secondaryGap),
                            child: InviteInfoRow(
                              icon: Icons.groups_2_outlined,
                              text: _participantLine(group),
                              maxLines: 2,
                            ),
                          ),
                        ),
                  ],
                  if (isCompact)
                    SizedBox(height: primaryGap)
                  else
                    const Spacer(),
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
                        'Ver detalhes',
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

  String _participantLine(EventRelatedProfileGroupSummary group) {
    final names = <String>[];
    final seen = <String>{};
    for (final name in group.profileNames) {
      final normalized = name.trim();
      if (normalized.isEmpty || !seen.add(normalized.toLowerCase())) {
        continue;
      }
      names.add(normalized);
    }

    if (names.isEmpty) {
      return group.label;
    }

    final visibleNames = names.take(2).join(', ');
    final remainingCount = names.length - 2;
    final compactNames = remainingCount > 0
        ? '$visibleNames, e mais $remainingCount'
        : visibleNames;
    final label = group.label.trim();
    return label.isEmpty ? compactNames : '$label: $compactNames';
  }
}
