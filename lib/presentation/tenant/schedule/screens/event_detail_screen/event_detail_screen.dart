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
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  late bool _isConfirmed;
  late List<SentInviteStatus> _sentInvites;
  late List<FriendResume> _friendsGoing;
  late int _totalConfirmed;
  late List<InviteModel> _receivedInvites;

  @override
  void initState() {
    super.initState();
    _isConfirmed = widget.event.isConfirmed;
    _sentInvites = widget.event.sentInvites ?? [];
    _friendsGoing = widget.event.friendsGoing ?? [];
    _totalConfirmed = widget.event.totalConfirmed;
    _receivedInvites = widget.event.receivedInvites ?? [];
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
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _receivedInvites.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: InviteBanner(
                              invite: _receivedInvites.first,
                              onAccept: _handleAcceptInvite,
                              onDecline: _handleDeclineInvite,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Confirmed Banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isConfirmed && _receivedInvites.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ConfirmedBanner(
                              confirmedAt:
                                  widget.event.confirmedAt ?? DateTime.now(),
                            ),
                          )
                        : const SizedBox.shrink(),
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
                  // Participants section (new model) or Artists (fallback)
                  if (widget.event.participants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Participantes',
                      style: theme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.event.participants
                          .map(
                            (participant) => EventParticipantPill(
                              name: participant.partner.displayName,
                              role: participant.role.value,
                              isHighlight: participant.isHighlight,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ] else if (widget.event.artists.isNotEmpty) ...[
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

                  // Invite Status Section (if confirmed)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isConfirmed
                        ? Column(
                            children: [
                              const SizedBox(height: 24),
                              InviteStatusSection(
                                sentInvites: _sentInvites,
                                onInvite: _handleInviteFriends,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Social Proof (if confirmed or has friends going)
                  if (_friendsGoing.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SocialProofSection(
                      friendsGoing: _friendsGoing,
                      totalConfirmed: _totalConfirmed,
                    ),
                  ],

                  // Quick Actions (if confirmed)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isConfirmed
                        ? Column(
                            children: [
                              const SizedBox(height: 8),
                              QuickActionsGrid(
                                onFavoriteArtists: () {}, // TODO: Implement
                                onFavoriteVenue: () {}, // TODO: Implement
                                onSetReminder: () {}, // TODO: Implement
                                onInviteFriends: _handleInviteFriends,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedBooraButton(
            isConfirmed: _isConfirmed && _receivedInvites.isEmpty,
            onPressed: _receivedInvites.isNotEmpty
                ? _handleAcceptInvite
                : (_isConfirmed ? null : _handleBooraAction),
            text: _getCTAButtonText(),
          ),
        ),
      ),
    );
  }

  String _getCTAButtonText() {
    if (_receivedInvites.isNotEmpty) {
      return 'Aceitar convite';
    }
    if (_isConfirmed) {
      return 'Confirmado ✓';
    }
    return 'Bóora!';
  }

  void _handleBooraAction() {
    setState(() {
      _isConfirmed = true;
    });
  }

  void _handleAcceptInvite() {
    setState(() {
      _isConfirmed = true;
      _receivedInvites = [];
    });
  }

  void _handleDeclineInvite() {
    setState(() {
      _receivedInvites = [];
    });
  }

  void _handleInviteFriends() {
    _openInviteFlow();
  }

  Future<void> _openInviteFlow() async {
    final invite = _buildInviteFromEvent();

    context.router.push(
      InviteShareRoute(
        invite: invite,
      ),
    );
  }

  // Keep for future use when implementing invite flow after confirmation
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
