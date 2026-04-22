import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDatesSection extends StatelessWidget {
  const EventDatesSection({
    required this.occurrences,
    required this.onOccurrenceTap,
    super.key,
  });

  final List<EventOccurrenceOption> occurrences;
  final ValueChanged<EventOccurrenceOption> onOccurrenceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Datas do evento',
            header: true,
            child: Text(
              'Datas do evento',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha uma data para ver agenda, local e programação específicos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ...occurrences.map(
            (occurrence) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventDateCard(
                occurrence: occurrence,
                onTap: () => onOccurrenceTap(occurrence),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDateCard extends StatelessWidget {
  const _EventDateCard({
    required this.occurrence,
    required this.onTap,
  });

  final EventOccurrenceOption occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = occurrence.isSelected;
    final start = occurrence.dateTimeStart;
    final end = occurrence.dateTimeEnd;
    final dateLabel = _formatDate(start);
    final timeLabel = _formatTimeRange(start, end);

    return Semantics(
      label: isSelected
          ? '$dateLabel, $timeLabel, Atual'
          : '$dateLabel, $timeLabel',
      selected: isSelected,
      button: !isSelected,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            key: Key('eventDateCard_${occurrence.occurrenceId}'),
            borderRadius: BorderRadius.circular(24),
            onTap: isSelected ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.16)
                          : colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.35)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      Icons.event_available,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              _CurrentOccurrenceBadge(
                                occurrenceId: occurrence.occurrenceId,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.78)
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (occurrence.hasLocationOverride ||
                            occurrence.programmingCount > 0) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (occurrence.hasLocationOverride)
                                const _OccurrenceMetaChip(
                                  label: 'Local específico',
                                  icon: Icons.place,
                                ),
                              if (occurrence.programmingCount > 0)
                                _OccurrenceMetaChip(
                                  label: occurrence.programmingCount == 1
                                      ? '1 item na programação'
                                      : '${occurrence.programmingCount} itens na programação',
                                  icon: Icons.schedule,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.chevron_right,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Data a confirmar';
    }
    return DateFormat("EEE, d 'de' MMM", 'pt_BR').format(value);
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null) {
      return 'Horario a confirmar';
    }
    final startLabel = DateFormat('HH:mm', 'pt_BR').format(start);
    if (end == null) {
      return startLabel;
    }
    final endLabel = DateFormat('HH:mm', 'pt_BR').format(end);
    return '$startLabel - $endLabel';
  }
}

class _CurrentOccurrenceBadge extends StatelessWidget {
  const _CurrentOccurrenceBadge({required this.occurrenceId});

  final String occurrenceId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Atual',
      child: Container(
        key: Key('eventDateCurrentBadge_$occurrenceId'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Atual',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _OccurrenceMetaChip extends StatelessWidget {
  const _OccurrenceMetaChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
