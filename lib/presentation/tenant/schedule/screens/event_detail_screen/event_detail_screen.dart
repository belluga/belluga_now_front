import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/artist_pill.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_detail_info_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_hint_list.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_type_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  final EventModel event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();

  static String _formatEventDateRange(
    DateTime start,
    DateTime? end,
  ) {
    final startLabel =
        DateFormat('EEE, d MMM • HH:mm', 'pt_BR').format(start.toLocal());
    if (end == null) {
      return startLabel;
    }

    final bool sameDay = DateUtils.isSameDay(start, end);
    final endLabel =
        DateFormat(sameDay ? 'HH:mm' : 'EEE, d MMM • HH:mm', 'pt_BR')
            .format(end.toLocal());
    return sameDay ? '$startLabel - $endLabel' : '$startLabel\naté $endLabel';
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1200';
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final DateTime startDate =
        widget.event.dateTimeStart.value ?? DateTime.now();
    final DateTime? endDate = widget.event.dateTimeEnd?.value;
    final coverUri = widget.event.thumb?.thumbUri.value;
    final String coverImage =
        coverUri?.toString() ?? EventDetailScreen._fallbackImage;
    final EventActionModel? primaryAction =
        widget.event.actions.isNotEmpty ? widget.event.actions.first : null;
    final EventTypeModel type = widget.event.type;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 16,
              ),
              title: Text(
                widget.event.title.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: kToolbarHeight + 24,
                    left: 20,
                    child: EventTypeChip(type: type),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventDetailInfoCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Quando',
                    value: EventDetailScreen._formatEventDateRange(
                        startDate, endDate),
                  ),
                  const SizedBox(height: 16),
                  EventDetailInfoCard(
                    icon: Icons.place_outlined,
                    label: 'Onde',
                    value: widget.event.location.value,
                  ),
                  if (widget.event.artists.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Line-up & Convidados',
                      style: theme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.event.artists
                            .map(
                              (artist) => EventArtistPill(
                                name: artist.displayName,
                                highlight: artist.isHighlight,
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Sobre o evento',
                    style: theme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    EventDetailScreen._stripHtml(
                        widget.event.content.value ?? ''),
                    style: theme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Saiba antes de ir',
                    style: theme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EventHintList(
                    hints: const [
                      'Chegue com 15 minutos de antecedência para organizar o grupo.',
                      'Leve uma garrafa reutilizável — água disponível no ponto de apoio.',
                      'Convites aceitos podem ser compartilhados com a sua rede dentro do app.',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (primaryAction != null) {
                    primaryAction.open(context);
                  } else {
                    _showComingSoon(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      primaryAction?.color?.value ?? colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  primaryAction?.label.value ?? 'Confirmar presença',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInviteFlow(),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Convidar amigos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve você poderá confirmar presença por aqui!'),
      ),
    );
  }

  Future<void> _openInviteFlow() async {
    final invite = _buildInviteFromEvent();

    context.router.push(
      InviteShareRoute(
        invite: invite,
      ),
    );
  }

  InviteModel _buildInviteFromEvent() {
    final eventName = widget.event.title.value;
    final eventDate = widget.event.dateTimeStart.value ?? DateTime.now();
    final inviteCoverUri = widget.event.thumb?.thumbUri.value;
    final imageUrl =
        inviteCoverUri?.toString() ?? EventDetailScreen._fallbackImage;
    final locationLabel = widget.event.location.value;
    final hostName = widget.event.artists.isNotEmpty
        ? widget.event.artists.first.displayName
        : 'Belluga Now';
    final description =
        EventDetailScreen._stripHtml(widget.event.content.value ?? '').trim();
    final slug = widget.event.type.slug.value;
    final typeLabel = widget.event.type.name.value;
    final tags = <String>[
      if (slug.isNotEmpty) slug,
      if (typeLabel.isNotEmpty && typeLabel != slug) typeLabel,
    ];

    final eventId = widget.event.id.value;
    final inviteId = eventId.isNotEmpty ? eventId : eventName;

    return InviteModel(
      id: inviteId,
      eventName: eventName,
      eventDateTime: eventDate,
      eventImageUrl: imageUrl,
      location: locationLabel,
      hostName: hostName,
      message: description.isEmpty ? 'Partiu $eventName?' : description,
      tags: tags.isEmpty ? const ['belluga'] : tags,
    );
  }
}

