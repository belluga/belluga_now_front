import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_event_footer.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_header_delegate.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/lineup_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/sua_galera_section.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ImmersiveEventDetailScreen extends StatefulWidget {
  const ImmersiveEventDetailScreen({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  State<ImmersiveEventDetailScreen> createState() =>
      _ImmersiveEventDetailScreenState();
}

class _ImmersiveEventDetailScreenState
    extends State<ImmersiveEventDetailScreen> {
  final _controller = GetIt.I.get<ImmersiveEventDetailController>();
  int _currentSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.init(widget.event);
    _controller.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _controller.scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    // Constants matching the UI
    const appBarExpandedHeight = 400.0;
    final appBarPinnedHeight = kToolbarHeight + topPadding;

    // The offset where the first section starts (when aligned to top under headers)
    // World Position of Section 0 = 400 + 48 = 448.
    // Target Screen Position = PinnedAppBar (56+padding) + Header (48).
    // Base Offset = 448 - (56 + padding + 48) = 400 - 56 - padding = 344 - padding.
    final baseOffset = appBarExpandedHeight - appBarPinnedHeight;

    // Calculate index relative to the start of the sections
    // If scrollOffset < baseOffset, we are in the hero/header area, so index 0.
    double relativeOffset = scrollOffset - baseOffset;

    int newIndex;
    if (relativeOffset < 0) {
      newIndex = 0;
    } else {
      // Add a small buffer (e.g. half screen) for snapping feel if desired,
      // but for "bring to top" behavior, strict threshold is usually better
      // or a small threshold like 100px.
      // Let's use 50% visibility to switch tabs.
      newIndex = ((relativeOffset + screenHeight * 0.5) / screenHeight).floor();
    }

    // Clamp based on actual number of sections
    final isConfirmed = _controller.isConfirmedStreamValue.value;
    final maxIndex = isConfirmed ? 3 : 2;
    final clampedIndex = newIndex.clamp(0, maxIndex);

    if (clampedIndex != _currentSectionIndex) {
      setState(() {
        _currentSectionIndex = clampedIndex;
      });
      _controller.updateActiveTab(clampedIndex);
      _scrollToSection(clampedIndex);
    }
  }

  void _scrollToSection(int index) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    const appBarExpandedHeight = 400.0;
    final appBarPinnedHeight = kToolbarHeight + topPadding;

    // Calculate the exact offset to bring the section to the top (under headers)
    final baseOffset = appBarExpandedHeight - appBarPinnedHeight;
    final targetOffset = baseOffset + (index * screenHeight);

    _controller.scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamValueBuilder<EventModel?>(
        streamValue: _controller.eventStreamValue,
        builder: (context, event) {
          if (event == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Main scrollable content
              CustomScrollView(
                controller: _controller.scrollController,
                slivers: [
                  // Immersive Hero with SliverAppBar
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // TODO: Share functionality
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: ImmersiveHero(event: event),
                      collapseMode: CollapseMode.parallax,
                    ),
                  ),

                  // Combined Social Proof + Tabs (single sticky header)
                  StreamValueBuilder<bool?>(
                    streamValue: _controller.isConfirmedStreamValue,
                    builder: (context, isConfirmed) {
                      final confirmed = isConfirmed ?? false;

                      return SliverPersistentHeader(
                        pinned: true,
                        delegate: ImmersiveHeaderDelegate(
                          isConfirmed: confirmed,
                          currentTabIndex: _currentSectionIndex,
                          onTabTapped: (index) => _scrollToSection(index),
                        ),
                      );
                    },
                  ),

                  // Sections using SliverFillViewport
                  StreamValueBuilder<bool?>(
                    streamValue: _controller.isConfirmedStreamValue,
                    builder: (context, isConfirmed) {
                      final confirmed = isConfirmed ?? false;

                      return SliverFillViewport(
                        delegate: SliverChildListDelegate([
                          if (confirmed)
                            SuaGaleraSection(
                              isConfirmedStream:
                                  _controller.isConfirmedStreamValue,
                              missionStream: _controller.missionStreamValue,
                              friendsGoingStream:
                                  _controller.friendsGoingStreamValue,
                            ),
                          EventInfoSection(event: event),
                          LineupSection(event: event),
                          LocationSection(event: event),
                        ]),
                      );
                    },
                  ),
                ],
              ),

              // Dynamic Footer
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ImmersiveEventFooter(
                  isConfirmedStream: _controller.isConfirmedStreamValue,
                  activeTabStream: _controller.activeTabStreamValue,
                  onConfirmAttendance: _controller.confirmAttendance,
                  onInviteFriends: () {
                    // TODO: Navigate to invite flow
                  },
                  onShowQrCode: () {
                    // TODO: Show QR code
                  },
                  onFollowArtists: () {
                    // TODO: Follow all artists
                  },
                  onTraceRoute: () {
                    // TODO: Open maps
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
