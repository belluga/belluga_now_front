import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/controllers/immersive_detail_screen_controller.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/immersive_header_delegate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Generic immersive detail screen with hero content, tabs, and dynamic footer.
///
/// This widget provides a reusable structure for immersive detail pages
/// (events, partners, users) with:
/// - Flexible hero content area
/// - Optional content between hero and tabs
/// - Dynamic tab configuration
/// - Theme-based styling (no hardcoded colors)
/// - Automatic scroll snapping to sections
class ImmersiveDetailScreen extends StatefulWidget {
  const ImmersiveDetailScreen({
    required this.heroContent,
    required this.title,
    required this.tabs,
    this.betweenHeroAndTabs,
    this.initialTabIndex = 0,
    this.footer,
    super.key,
  });

  /// Widget displayed in the hero area (typically an image or custom content)
  final Widget heroContent;

  /// Title displayed in the AppBar when collapsed
  final String title;

  /// Optional widget displayed between hero and tabs
  final Widget? betweenHeroAndTabs;

  /// List of tab configurations
  final List<ImmersiveTabItem> tabs;

  /// Initial tab index (defaults to 0)
  final int initialTabIndex;

  /// Optional default footer widget
  /// Individual tabs can override this with their own footer
  final Widget? footer;

  @override
  State<ImmersiveDetailScreen> createState() => _ImmersiveDetailScreenState();
}

class _ImmersiveDetailScreenState extends State<ImmersiveDetailScreen> {
  late final ImmersiveDetailScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImmersiveDetailScreenController(
      initialTabIndex: widget.initialTabIndex,
      tabItems: widget.tabs,
    );
  }

  @override
  void didUpdateWidget(covariant ImmersiveDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final titlesChanged = !listEquals(
      oldWidget.tabs.map((t) => t.title).toList(),
      widget.tabs.map((t) => t.title).toList(),
    );

    if (oldWidget.tabs.length != widget.tabs.length || titlesChanged) {
      _controller.updateTabs(widget.tabs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    _controller.setTopPadding(topPadding);
    const appBarExpandedHeight = 400.0;

    return Scaffold(
      // Use LayoutBuilder to get the exact available height for the body
      // This accounts for the Scaffold's bottomNavigationBar (footer) automatically
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The total available height for the NestedScrollView
          final availableHeight = constraints.maxHeight;

          // The height of the pinned header (StatusBar + AppBar + Tabs)
          final pinnedHeaderHeight = topPadding + kToolbarHeight + 48.0;

          // The minimum height for each tab content to fill the viewport
          // We subtract the pinned header height from the available height
          final minTabHeight = availableHeight - pinnedHeaderHeight;

          return NestedScrollView(
            key: _controller.nestedScrollViewKey,
            controller: _controller.scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: appBarExpandedHeight,
                  pinned: true,
                  stretch: true,
                  backgroundColor: colorScheme.surface,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: innerBoxIsScrolled
                        ? colorScheme.onSurface
                        : Colors.white,
                    onPressed: () => context.router.pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      color: innerBoxIsScrolled
                          ? colorScheme.onSurface
                          : Colors.white,
                      onPressed: () {
                        // TODO: Share functionality
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.heroContent,
                        // Scrim gradient for icon visibility
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: innerBoxIsScrolled
                        ? Text(
                            widget.title,
                            style: TextStyle(color: colorScheme.onSurface),
                          )
                        : null,
                    centerTitle: true,
                  ),
                ),
                // Optional content between hero and tabs
                if (widget.betweenHeroAndTabs != null)
                  SliverToBoxAdapter(
                    child: widget.betweenHeroAndTabs,
                  ),
                StreamValueBuilder<int>(
                    streamValue: _controller.currentTabIndexStreamValue,
                    builder: (context, currentTabIndex) {
                      return SliverPersistentHeader(
                        pinned: true,
                        delegate: ImmersiveHeaderDelegate(
                          tabs: widget.tabs.map((t) => t.title).toList(),
                          currentTabIndex: currentTabIndex,
                          onTabTapped: _controller.onTabTapped,
                          colorScheme: colorScheme,
                          topPadding: 0,
                        ),
                      );
                    }),
              ];
            },
            body: SingleChildScrollView(
              child: Column(
                children: widget.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  return VisibilityDetector(
                    key: Key('tab_visibility_$index'),
                    onVisibilityChanged: (info) {
                      _controller.onTabVisibilityChanged(
                          index, info.visibleFraction);
                    },
                    child: Container(
                      key: _controller.tabItems[index].key,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minTabHeight,
                        ),
                        child: tab.content,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: StreamValueBuilder<int>(
          streamValue: _controller.currentTabIndexStreamValue,
          builder: (context, currentTabIndex) {
            if (_controller.tabItems.isEmpty) {
              return const SizedBox.shrink();
            }

            final safeIndex = currentTabIndex.clamp(
              0,
              _controller.tabItems.length - 1,
            );

            return _controller.tabItems[safeIndex].footer ??
                widget.footer ??
                const SizedBox.shrink();
          }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
