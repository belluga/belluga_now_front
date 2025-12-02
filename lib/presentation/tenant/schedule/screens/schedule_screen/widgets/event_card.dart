import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_action_button.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_bottom_sheet.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_participants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => _showEventBottomSheet(context, widget.event),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.event.title.value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildEventDate(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
              if (_plainDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _plainDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              EventParticipants(artists: widget.event.artists),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.event.actions
                    .map(
                      (action) => EventActionButton(eventAction: action),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEventBottomSheet(
      BuildContext context, EventModel event) async {
    FocusScope.of(context).requestFocus(FocusNode());

    await showModalBottomSheet(
      context: context,
      useSafeArea: false,
      builder: (_) => EventBottomSheet(event: event),
    );
  }

  String get _plainDescription {
    final raw = widget.event.content.value;
    if (raw == null || raw.isEmpty) {
      return '';
    }

    final stripped = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return stripped;
  }

  String _buildEventDate(BuildContext context) {
    final date = widget.event.dateTimeStart.value;
    if (date == null) {
      return 'Data a definir';
    }

    final formattedDate = DateFormat.MMMMEEEEd().format(date);
    final formattedHour = DateFormat.Hm().format(date);
    return 'Data: $formattedDate as ${formattedHour}h';
  }
}
