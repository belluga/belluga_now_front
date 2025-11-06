import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
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
    final DateTime startDate = widget.event.dateTimeStart.value ?? DateTime.now();
    final DateTime? endDate = widget.event.dateTimeEnd?.value;
    final String coverImage =
        widget.event.thumb?.thumbUri.value?.toString() ?? EventDetailScreen._fallbackImage;
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
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: kToolbarHeight + 24,
                    left: 20,
                    child: _TypeChip(type: type),
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
                  _InfoCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Quando',
                    value: EventDetailScreen._formatEventDateRange(startDate, endDate),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
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
                            (artist) => _ArtistPill(
                              name: artist.name.value,
                              highlight: artist.isHighlight.value ?? false,
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
                    EventDetailScreen._stripHtml(widget.event.content.value ?? ''),
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
                  _HintList(
                    hints: [
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

  void _copyLink(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para compartilhar com a galera!'),
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
    final imageUrl = widget.event.thumb?.thumbUri.value?.toString() ?? EventDetailScreen._fallbackImage;
    final locationLabel = widget.event.location.value;
    final hostName = widget.event.artists.isNotEmpty
        ? widget.event.artists.first.name.value
        : 'Belluga Now';
    final description = EventDetailScreen._stripHtml(widget.event.content.value ?? '').trim();
    final slug = widget.event.type.slug.value;
    final typeLabel = widget.event.type.name.value;
    final tags = <String>[
      if (slug.isNotEmpty) slug,
      if (typeLabel.isNotEmpty && typeLabel != slug) typeLabel,
    ];

    return InviteModel(
      id: widget.event.id.value ?? eventName,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final EventTypeModel type;

  @override
  Widget build(BuildContext context) {
    final Color color = type.color.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: color.withOpacity(0.16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          type.name.value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withOpacity(0.08),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistPill extends StatelessWidget {
  const _ArtistPill({
    required this.name,
    required this.highlight,
  });

  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color foreground =
        highlight ? colorScheme.onPrimary : colorScheme.onSurface;
    final Color background =
        highlight ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: background,
        border: highlight
            ? null
            : Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Text(
        highlight ? '$name ★' : name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _HintList extends StatelessWidget {
  const _HintList({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hints
          .map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hint,
                      style: theme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
