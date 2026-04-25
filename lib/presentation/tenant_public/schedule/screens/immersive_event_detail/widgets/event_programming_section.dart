import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_type_avatar.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _initialVisibleProgrammingItems = 24;
const _visibleProgrammingItemsPageSize = 24;
const _visibleProgrammingProfilesPerItem = 4;

class EventProgrammingSection extends StatefulWidget {
  const EventProgrammingSection({
    required this.items,
    required this.occurrences,
    required this.onOccurrenceTap,
    required this.onLocationTap,
    required this.profileTypeRegistry,
    super.key,
  });

  final List<EventProgrammingItem> items;
  final List<EventOccurrenceOption> occurrences;
  final ValueChanged<EventOccurrenceOption> onOccurrenceTap;
  final ValueChanged<EventLinkedAccountProfile> onLocationTap;
  final ProfileTypeRegistry? profileTypeRegistry;

  @override
  State<EventProgrammingSection> createState() =>
      _EventProgrammingSectionState();
}

class _EventProgrammingSectionState extends State<EventProgrammingSection> {
  int _visibleItemCount = _initialVisibleProgrammingItems;

  @override
  void didUpdateWidget(covariant EventProgrammingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _visibleItemCount = _initialVisibleProgrammingItems;
    }
  }

  void _showMoreItems() {
    setState(() {
      _visibleItemCount = (_visibleItemCount + _visibleProgrammingItemsPageSize)
          .clamp(0, widget.items.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = widget.items.take(_visibleItemCount).toList(
          growable: false,
        );
    final remainingItemCount = widget.items.length - visibleItems.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programação',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.occurrences.length > 1) ...[
            const SizedBox(height: 14),
            _ProgrammingDateSelector(
              occurrences: widget.occurrences,
              onOccurrenceTap: widget.onOccurrenceTap,
            ),
          ],
          const SizedBox(height: 18),
          if (widget.items.isEmpty)
            _ProgrammingEmptyState()
          else ...[
            for (final entry in visibleItems.asMap().entries)
              Padding(
                key: Key(
                  'eventProgrammingItemSlot_${entry.key}_${entry.value.time}',
                ),
                padding: const EdgeInsets.only(bottom: 12),
                child: RepaintBoundary(
                  child: _ProgrammingCard(
                    item: entry.value,
                    itemIndex: entry.key,
                    onLocationTap: widget.onLocationTap,
                    profileTypeRegistry: widget.profileTypeRegistry,
                  ),
                ),
              ),
            if (remainingItemCount > 0)
              _ShowMoreProgrammingItemsButton(
                remainingItemCount: remainingItemCount,
                onPressed: _showMoreItems,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgrammingDateSelector extends StatelessWidget {
  const _ProgrammingDateSelector({
    required this.occurrences,
    required this.onOccurrenceTap,
  });

  final List<EventOccurrenceOption> occurrences;
  final ValueChanged<EventOccurrenceOption> onOccurrenceTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: occurrences.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final occurrence = occurrences[index];
          return _ProgrammingDateChip(
            occurrence: occurrence,
            onTap: () => onOccurrenceTap(occurrence),
          );
        },
      ),
    );
  }
}

class _ShowMoreProgrammingItemsButton extends StatelessWidget {
  const _ShowMoreProgrammingItemsButton({
    required this.remainingItemCount,
    required this.onPressed,
  });

  final int remainingItemCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = remainingItemCount == 1
        ? 'Mostrar mais 1 item'
        : 'Mostrar mais $remainingItemCount itens';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('eventProgrammingShowMoreButton'),
        onPressed: onPressed,
        icon: const Icon(Icons.expand_more),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ProgrammingDateChip extends StatelessWidget {
  const _ProgrammingDateChip({
    required this.occurrence,
    required this.onTap,
  });

  final EventOccurrenceOption occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final start = occurrence.dateTimeStart;
    final isSelected = occurrence.isSelected;
    final dateLabel =
        start == null ? 'Data' : DateFormat('dd/MM').format(start);
    final weekdayLabel = _formatWeekday(start);

    return Semantics(
      label: weekdayLabel.isEmpty ? dateLabel : '$dateLabel, $weekdayLabel',
      selected: isSelected,
      button: !isSelected,
      child: InkWell(
        key: Key('eventDateCard_${occurrence.occurrenceId}'),
        onTap: isSelected ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (weekdayLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  weekdayLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatWeekday(DateTime? value) {
    if (value == null) {
      return '';
    }
    final label = DateFormat('EEEE', 'pt_BR')
        .format(value)
        .replaceAll('.', '')
        .replaceAll('-feira', '')
        .trim();
    if (label.isEmpty) {
      return '';
    }
    return '${label[0].toUpperCase()}${label.substring(1).toLowerCase()}';
  }
}

class _ProgrammingEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('eventProgrammingEmptyState'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        'Esta data ainda não tem programação cadastrada.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProgrammingCard extends StatelessWidget {
  const _ProgrammingCard({
    required this.item,
    required this.itemIndex,
    required this.onLocationTap,
    required this.profileTypeRegistry,
  });

  final EventProgrammingItem item;
  final int itemIndex;
  final ValueChanged<EventLinkedAccountProfile> onLocationTap;
  final ProfileTypeRegistry? profileTypeRegistry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = item.displayTitle.trim();
    final hasTitle = title.isNotEmpty;
    final hasProfiles = item.linkedAccountProfiles.isNotEmpty;
    final hasLocation = item.locationProfile != null;
    final hasSecondaryContent = hasProfiles || hasLocation;
    final visibleProfiles = item.linkedAccountProfiles
        .take(_visibleProgrammingProfilesPerItem)
        .toList(growable: false);
    final remainingProfileCount =
        item.linkedAccountProfiles.length - visibleProfiles.length;

    return DecoratedBox(
      key: Key('eventProgrammingItem_${itemIndex}_${item.time}'),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: hasSecondaryContent
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                item.time,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle)
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (hasProfiles) ...[
                    if (hasTitle) const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final profile in visibleProfiles)
                          _ProgrammingProfileChip(
                            profile: profile,
                            profileTypeRegistry: profileTypeRegistry,
                          ),
                        if (remainingProfileCount > 0)
                          _ProgrammingProfileOverflowChip(
                            itemIndex: itemIndex,
                            remainingProfileCount: remainingProfileCount,
                          ),
                      ],
                    ),
                  ],
                  if (hasLocation) ...[
                    const SizedBox(height: 12),
                    _ProgrammingLocationLine(
                      profile: item.locationProfile!,
                      onTap: () => onLocationTap(item.locationProfile!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgrammingLocationLine extends StatelessWidget {
  const _ProgrammingLocationLine({
    required this.profile,
    required this.onTap,
  });

  final EventLinkedAccountProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('eventProgrammingLocation_${profile.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgrammingProfileOverflowChip extends StatelessWidget {
  const _ProgrammingProfileOverflowChip({
    required this.itemIndex,
    required this.remainingProfileCount,
  });

  final int itemIndex;
  final int remainingProfileCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = remainingProfileCount == 1
        ? '+1 perfil'
        : '+$remainingProfileCount perfis';
    return Container(
      key: Key('eventProgrammingProfilesOverflow_$itemIndex'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ProgrammingProfileChip extends StatelessWidget {
  const _ProgrammingProfileChip({
    required this.profile,
    required this.profileTypeRegistry,
  });

  final EventLinkedAccountProfile profile;
  final ProfileTypeRegistry? profileTypeRegistry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.56;
    final resolvedVisual = AccountProfileVisualResolver.resolvePreview(
      registry: profileTypeRegistry,
      profileType: profile.profileType,
      avatarUrl: profile.avatarUrl,
      coverUrl: profile.coverUrl,
    );
    return Container(
      key: Key('eventProgrammingProfile_${profile.id}'),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProgrammingProfileVisual(
            profile: profile,
            resolvedVisual: resolvedVisual,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgrammingProfileVisual extends StatelessWidget {
  const _ProgrammingProfileVisual({
    required this.profile,
    required this.resolvedVisual,
  });

  final EventLinkedAccountProfile profile;
  final ResolvedAccountProfileVisual resolvedVisual;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: BellugaNetworkImage(
          avatarUrl,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          errorWidget: _buildFallback(context),
        ),
      );
    }

    final typeVisual = resolvedVisual.typeVisual;
    if (typeVisual != null) {
      return AccountProfileTypeAvatar(
        visual: typeVisual,
        size: 18,
        iconSize: 10,
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 11,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
