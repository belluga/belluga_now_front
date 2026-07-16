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
    required this.isIssuerPreview,
    required this.onSharePreview,
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
  final bool isIssuerPreview;
  final VoidCallback onSharePreview;

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
          final panelColor = Colors.black.withValues(alpha: 0.72);
          final contentColor = Colors.white;
          final detailsPadding = EdgeInsets.symmetric(
            vertical: isCompact ? 10 : 12,
          );
          final titleStyle =
              (isCompact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(color: contentColor, fontWeight: FontWeight.w800);
          final accessibilitySummary = _buildAccessibilitySummary();
          final details = Column(
            mainAxisSize: MainAxisSize.min,
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
                ...participantGroups
                    .take(isCompact ? 2 : 3)
                    .map(
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

          return Stack(
            fit: StackFit.expand,
            children: [
              BellugaNetworkImage(
                heroImage,
                fit: BoxFit.cover,
                semanticLabel: title,
                errorWidget: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scrim.withValues(alpha: 0.18),
                      scrim.withValues(alpha: 0.06),
                      scrim.withValues(alpha: 0.58),
                      scrim.withValues(alpha: 0.82),
                    ],
                    stops: const [0, 0.3, 0.62, 1],
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
                    isIssuerPreview: isIssuerPreview,
                    onSharePreview: onSharePreview,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding,
                    constraints.maxHeight * 0.22,
                    contentPadding,
                    contentPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight - (contentPadding * 2),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          isCompact ? 12 : 16,
                          contentPadding,
                          contentPadding,
                        ),
                        child: Semantics(
                          container: true,
                          label: accessibilitySummary,
                          child: details,
                        ),
                      ),
                    ),
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

  String _buildAccessibilitySummary() {
    final segments = <String>[
      title.trim(),
      dateLabel.trim(),
      location.trim(),
      if (showHost) host.trim(),
      for (final group in participantGroups) _participantLine(group).trim(),
    ].where((segment) => segment.isNotEmpty);

    return segments.join(' ');
  }
}
