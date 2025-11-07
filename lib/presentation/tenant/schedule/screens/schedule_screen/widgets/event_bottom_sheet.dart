import 'package:belluga_now/domain/schedule/event_artist_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_action_button.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventBottomSheet extends StatelessWidget {
  const EventBottomSheet({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventDate = event.dateTimeStart.value;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.type.name.value,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.title.value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (eventDate != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat.MMMMEEEEd().format(eventDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat.Hm().format(eventDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_plainDescription.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        _plainDescription,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (event.artists.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Curadoria',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EventArtistsList(artists: event.artists),
                    ],
                    if (event.actions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: event.actions
                            .map(
                              (action) =>
                                  EventActionButton(eventAction: action),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _plainDescription {
    final raw = event.content.value;
    if (raw == null || raw.isEmpty) {
      return '';
    }

    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class _EventArtistsList extends StatelessWidget {
  const _EventArtistsList({required this.artists});

  final List<EventArtistModel> artists;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return EventInfoRow(
        icon: Icons.groups_outlined,
        label: 'Curadoria em definição',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    return Column(
      children: artists
          .map(
            (artist) => _EventArtistTile(artist: artist),
          )
          .toList(),
    );
  }
}

class _EventArtistTile extends StatelessWidget {
  const _EventArtistTile({required this.artist});

  final EventArtistModel artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUri = artist.avatarUrl.value?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: artist.isHighlight.value
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageUri != null ? NetworkImage(imageUri) : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: imageUri == null
              ? Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        title: Text(
          artist.name.value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight:
                artist.isHighlight.value ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: artist.isHighlight.value
            ? Text(
                'Destaque confirmado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }
}
