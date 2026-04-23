import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventProgrammingSection extends StatelessWidget {
  const EventProgrammingSection({
    required this.items,
    required this.occurrences,
    required this.onOccurrenceTap,
    required this.onLocationTap,
    super.key,
  });

  final List<EventProgrammingItem> items;
  final List<EventOccurrenceOption> occurrences;
  final ValueChanged<EventOccurrenceOption> onOccurrenceTap;
  final ValueChanged<EventLinkedAccountProfile> onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          if (occurrences.length > 1) ...[
            const SizedBox(height: 14),
            _ProgrammingDateSelector(
              occurrences: occurrences,
              onOccurrenceTap: onOccurrenceTap,
            ),
          ],
          const SizedBox(height: 18),
          if (items.isEmpty)
            _ProgrammingEmptyState()
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProgrammingCard(
                  item: item,
                  onLocationTap: onLocationTap,
                ),
              ),
            ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final occurrence in occurrences)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _ProgrammingDateChip(
                occurrence: occurrence,
                onTap: () => onOccurrenceTap(occurrence),
              ),
            ),
        ],
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
    final timeLabel = start == null ? '' : DateFormat('HH:mm').format(start);

    return InkWell(
      key: Key('eventDateCard_${occurrence.occurrenceId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (timeLabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                key: Key('eventDateCurrentBadge_${occurrence.occurrenceId}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Atual',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
    required this.onLocationTap,
  });

  final EventProgrammingItem item;
  final ValueChanged<EventLinkedAccountProfile> onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = item.displayTitle.trim().isEmpty
        ? 'Atividade'
        : item.displayTitle.trim();

    return DecoratedBox(
      key: Key('eventProgrammingItem_${item.time}'),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.linkedAccountProfiles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.linkedAccountProfiles
                          .map(
                            (profile) => _ProgrammingProfileChip(
                              name: profile.displayName,
                              profileId: profile.id,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (item.locationProfile != null) ...[
                    const SizedBox(height: 12),
                    _ProgrammingLocationButton(
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

class _ProgrammingLocationButton extends StatelessWidget {
  const _ProgrammingLocationButton({
    required this.profile,
    required this.onTap,
  });

  final EventLinkedAccountProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('eventProgrammingLocation_${profile.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgrammingProfileChip extends StatelessWidget {
  const _ProgrammingProfileChip({
    required this.name,
    required this.profileId,
  });

  final String name;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: Key('eventProgrammingProfile_$profileId'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
