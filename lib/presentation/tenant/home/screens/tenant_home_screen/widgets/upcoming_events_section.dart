import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({
    super.key,
    required this.controller,
    required this.onExplore,
    required this.onEventSelected,
  });

  final TenantHomeController controller;
  final VoidCallback onExplore;
  final ValueChanged<String> onEventSelected;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<VenueEventResume>>(
      streamValue: controller.upcomingEventsStreamValue,
      builder: (context, events) {
        if (events.isEmpty) {
          return EmptyUpcomingEventsState(onExplore: onExplore);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final event = events[index];
            return UpcomingEventCard(
              event: event,
              onTap: () => onEventSelected(event.slug),
            );
          },
        );
      },
    );
  }
}

class EmptyUpcomingEventsState extends StatelessWidget {
  const EmptyUpcomingEventsState({
    super.key,
    required this.onExplore,
  });

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sem próximos eventos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Confirme convites na agenda para vê-los por aqui.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Ir para agenda'),
            ),
          ],
        ),
      ),
    );
  }
}
