import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;

class TenantAdminProgrammingItemCard extends StatelessWidget {
  const TenantAdminProgrammingItemCard({
    super.key,
    required this.item,
    required this.venues,
    required this.onTap,
    required this.onRemove,
    this.dragHandle,
  });

  final TenantAdminEventProgrammingItem item;
  final List<TenantAdminAccountProfile> venues;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleHtml = SafeRichHtml.canonicalize(item.title?.trim() ?? '');
    final hasHtmlTitle = !SafeRichHtml.isEffectivelyEmpty(titleHtml);
    final titleText = hasHtmlTitle
        ? _plainTextFromHtml(titleHtml)
        : _firstProgrammingProfileName(item) ?? 'Item sem título';
    final subtitleLines = _subtitleLines(item, venues);
    final isSequential = item.isSequential;
    final semanticLabel = [
      isSequential ? 'Sequencial' : 'Fixo',
      if (item.hasTime) _timeLabel(item),
      titleText,
      ...subtitleLines,
    ].join('\n');

    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dragHandle != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: dragHandle!,
                  ),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _ProgrammingModeLabel(isSequential: isSequential),
                          if (item.hasTime)
                            Text(
                              _timeLabel(item),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (hasHtmlTitle)
                        Html(
                          data: titleHtml,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              color: colorScheme.onSurface,
                              fontSize: FontSize(
                                theme.textTheme.bodyLarge?.fontSize ?? 16,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                            'p': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                          },
                        )
                      else
                        Text(
                          titleText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (subtitleLines.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        for (final line in subtitleLines)
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover item de programação',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _timeLabel(TenantAdminEventProgrammingItem item) {
    final endTime = item.endTime;
    return endTime == null ? item.time : '${item.time} às $endTime';
  }

  static String? _firstProgrammingProfileName(
    TenantAdminEventProgrammingItem item,
  ) {
    return item.linkedAccountProfiles.firstOrNull?.displayName;
  }

  static List<String> _subtitleLines(
    TenantAdminEventProgrammingItem item,
    List<TenantAdminAccountProfile> venues,
  ) {
    final locationLabel = _locationDisplayName(item, venues);
    return [
      '${item.accountProfileIds.length} perfil(is) vinculado(s)',
      if (locationLabel != null) 'Local: $locationLabel',
    ];
  }

  static String? _locationDisplayName(
    TenantAdminEventProgrammingItem item,
    List<TenantAdminAccountProfile> venues,
  ) {
    final savedLocation = item.locationProfile;
    if (savedLocation != null) {
      return savedLocation.displayName;
    }
    final placeRef = item.placeRef;
    if (placeRef == null) {
      return null;
    }
    for (final venue in venues) {
      if (venue.id == placeRef.id) {
        return venue.displayName;
      }
    }
    return null;
  }

  static String _plainTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ProgrammingModeLabel extends StatelessWidget {
  const _ProgrammingModeLabel({required this.isSequential});

  final bool isSequential;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSequential ? colorScheme.tertiary : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isSequential ? 'Sequencial' : 'Fixo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
