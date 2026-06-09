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
    final colorScheme = theme.colorScheme;
    final scrim = colorScheme.scrim;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxHeight < 430 || constraints.maxWidth < 280;
          final contentPadding = isCompact ? 12.0 : 16.0;
          final primaryGap = isCompact ? 8.0 : 12.0;
          final secondaryGap = isCompact ? 6.0 : 8.0;
          final panelColor = colorScheme.surface.withValues(alpha: 0.96);
          final contentColor = colorScheme.onSurface;
          final detailsPadding = EdgeInsets.symmetric(
            vertical: isCompact ? 10 : 12,
          );
          final titleStyle = (isCompact
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineSmall)
              ?.copyWith(
            color: contentColor,
            fontWeight: FontWeight.w800,
          );
          final imageHeight = (constraints.maxHeight * (isCompact ? 0.26 : 0.3))
              .clamp(120.0, isCompact ? 156.0 : 180.0);

          final details = Column(
            mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              SizedBox(height: primaryGap),
              InviteInfoRow(
                icon: Icons.event,
                text: dateLabel,
                maxLines: 2,
                color: contentColor,
              ),
              SizedBox(height: secondaryGap),
              InviteInfoRow(
                icon: Icons.place,
                text: location,
                maxLines: 2,
                color: contentColor,
              ),
              if (showHost) ...[
                SizedBox(height: secondaryGap),
                InviteInfoRow(
                  icon: Icons.storefront_outlined,
                  text: host,
                  maxLines: 2,
                  color: contentColor,
                ),
              ],
              if (participantGroups.isNotEmpty) ...[
                SizedBox(height: primaryGap),
                Text(
                  'Participantes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: contentColor,
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
                          color: contentColor,
                        ),
                      ),
                    ),
              ],
              if (!isCompact) const Spacer(),
              SizedBox(height: isCompact ? primaryGap : primaryGap + 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onViewDetails,
                  style: FilledButton.styleFrom(
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
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
                            scrim.withValues(alpha: 0.2),
                            scrim.withValues(alpha: 0.06),
                            panelColor,
                          ],
                          stops: const [0, 0.55, 1],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(contentPadding),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: InviterPill(
                          inviter: inviter,
                          extraInviters: extraInviters,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: panelColor),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      contentPadding,
                      isCompact ? 10 : 14,
                      contentPadding,
                      contentPadding,
                    ),
                    child: isCompact
                        ? SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: details,
                          )
                        : details,
                  ),
                ),
              ),
            ],
          );
        },
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
