import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/animated_boora_button.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/artist_pill.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/confirmed_banner.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_detail_header.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_detail_info_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_hint_list.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/event_participant_pill.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/invite_banner.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/invite_status_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/quick_actions_grid.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/social_proof_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/venue_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  final EventModel event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();

  static String _formatEventDateRange(DateTime start, DateTime? end) {
    final startLabel =
        DateFormat('EEE, d MMM • HH:mm', 'pt_BR').format(start.toLocal());
    if (end == null) return startLabel;
    final bool sameDay = DateUtils.isSameDay(start, end);
    final endLabel =
        DateFormat(sameDay ? 'HH:mm' : 'EEE, d MMM • HH:mm', 'pt_BR')
            .format(end.toLocal());
    return sameDay ? '$startLabel - $endLabel' : '$startLabel\\naté $endLabel';
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1200';
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventDetailController _controller = GetIt.I<EventDetailController>();

  @override
  void initState() {
    super.initState();
    // Load event details using slug (ensures latest confirmation state)
    _controller.loadEventBySlug(widget.event.slug);
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

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
    final EventTypeModel type = widget.event.type;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          EventDetailHeader(
            title: widget.event.title.value,
            coverImage: coverImage,
            type: type,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Received Invite Banner
                  StreamValueBuilder<List<InviteModel>>(
                    streamValue: _controller.receivedInvitesStreamValue,
                    builder: (context, receivedInvites) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: receivedInvites.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: InviteBanner(
                                  invite: receivedInvites.first,
                                  onAccept: _handleAcceptInvite,
                                  onDecline: _handleDeclineInvite,
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                  // Confirmed Banner
                  StreamValueBuilder<bool>(
                    streamValue: _controller.isConfirmedStreamValue,
                    builder: (context, isConfirmed) {
                      return StreamValueBuilder<List<InviteModel>>(
                        streamValue: _controller.receivedInvitesStreamValue,
                        builder: (context, receivedInvites) {
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: isConfirmed && receivedInvites.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: ConfirmedBanner(
                                      confirmedAt: widget.event.confirmedAt ??
                                          DateTime.now(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  ),
                  // Event Details
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
                  // Venue section
                  if (widget.event.venue != null) ...[
                    const SizedBox(height: 16),
                    VenueCard(venue: widget.event.venue!),
                  ],
                  // Participants or Artists
                  if (widget.event.participants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Participantes',
                      style: theme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.event.participants
                          .map((p) => EventParticipantPill(
                                name: p.partner.displayName,
                                role: p.role.value,
                                isHighlight: p.isHighlight,
                              ))
                          .toList(growable: false),
                    ),
                  ] else if (widget.event.artists.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Line-up & Convidados',
                      style: theme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.event.artists
                          .map((a) => EventArtistPill(
                                name: a.displayName,
                                highlight: a.isHighlight,
                              ))
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Sobre o evento',
                    style: theme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Html(
                    data: widget.event.content.value ?? '',
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(theme.bodyLarge?.fontSize ?? 16.0),
                        lineHeight: LineHeight.number(1.5),
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      'p': Style(margin: Margins.only(bottom: 12)),
                      'h1, h2, h3': Style(
                        fontWeight: FontWeight.w700,
                        margin: Margins.only(top: 16, bottom: 8),
                      ),
                      'ul, ol': Style(
                        margin: Margins.only(left: 16, bottom: 12),
                      ),
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Saiba antes de ir',
                    style: theme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  EventHintList(
                    hints: const [
                      'Chegue com 15 minutos de antecedência para organizar o grupo.',
                      'Leve uma garrafa reutilizável — água disponível no ponto de apoio.',
                      'Convites aceitos podem ser compartilhados com a sua rede dentro do app.',
                    ],
                  ),
                  // Invite Status Section (if confirmed)
                  StreamValueBuilder<bool>(
                    streamValue: _controller.isConfirmedStreamValue,
                    builder: (context, isConfirmed) {
                      return StreamValueBuilder<
                          Map<String, List<SentInviteStatus>>>(
                        streamValue: _controller.sentInvitesByEventStreamValue,
                        builder: (context, sentInvitesMap) {
                          final sentInvites =
                              sentInvitesMap[widget.event.id.value] ?? [];
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: isConfirmed
                                ? Column(
                                    children: [
                                      const SizedBox(height: 24),
                                      InviteStatusSection(
                                        sentInvites: sentInvites,
                                        onInvite: _handleInviteFriends,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  ),
                  // Social Proof (if confirmed or has friends going)
                  StreamValueBuilder<List<EventFriendResume>>(
                    streamValue: _controller.friendsGoingStreamValue,
                    builder: (context, friendsGoing) {
                      return StreamValueBuilder<int>(
                        streamValue: _controller.totalConfirmedStreamValue,
                        builder: (context, totalConfirmed) {
                          if (friendsGoing.isEmpty)
                            return const SizedBox.shrink();
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              SocialProofSection(
                                friendsGoing: friendsGoing,
                                totalConfirmed: totalConfirmed,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // Quick Actions (if confirmed)
                  StreamValueBuilder<bool>(
                    streamValue: _controller.isConfirmedStreamValue,
                    builder: (context, isConfirmed) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: isConfirmed
                            ? Column(
                                children: [
                                  const SizedBox(height: 8),
                                  QuickActionsGrid(
                                    onFavoriteArtists: () {},
                                    onFavoriteVenue: () {},
                                    onSetReminder: () {},
                                    onInviteFriends: _handleInviteFriends,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StreamValueBuilder<bool>(
        streamValue: _controller.isConfirmedStreamValue,
        builder: (context, isConfirmed) {
          return StreamValueBuilder<List<InviteModel>>(
            streamValue: _controller.receivedInvitesStreamValue,
            builder: (context, receivedInvites) {
              return SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedBooraButton(
                    isConfirmed: isConfirmed && receivedInvites.isEmpty,
                    onPressed: receivedInvites.isNotEmpty
                        ? _handleAcceptInvite
                        : (isConfirmed ? null : _handleBooraAction),
                    text: _getCTAButtonText(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getCTAButtonText() {
    final receivedInvites = _controller.receivedInvitesStreamValue.value;
    final isConfirmed = _controller.isConfirmedStreamValue.value;
    if (receivedInvites.isNotEmpty) return 'Aceitar convite';
    if (isConfirmed) return 'Confirmado ✓';
    return 'Bóora!';
  }

  void _handleBooraAction() {
    _controller.confirmAttendance();
  }

  void _handleAcceptInvite() {
    final firstInvite =
        _controller.receivedInvitesStreamValue.value.firstOrNull;
    if (firstInvite != null) {
      _controller.acceptInvite(firstInvite.id);
    }
  }

  void _handleDeclineInvite() {
    final firstInvite =
        _controller.receivedInvitesStreamValue.value.firstOrNull;
    if (firstInvite != null) {
      _controller.declineInvite(firstInvite.id);
    }
  }

  void _handleInviteFriends() {
    _openInviteFlow();
  }

  Future<void> _openInviteFlow() async {
    final invite = _buildInviteFromEvent();
    context.router.push(InviteShareRoute(invite: invite));
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
    return InviteModel.fromPrimitives(
      id: inviteId,
      eventId: eventId,
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
