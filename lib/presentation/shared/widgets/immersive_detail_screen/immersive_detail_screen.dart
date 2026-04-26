import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/controllers/immersive_detail_screen_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_header_delegate.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
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
    required this.backPolicy,
    this.betweenHeroAndTabs,
    this.initialTabIndex = 0,
    this.footer,
    this.collapsedTitle,
    this.collapsedToolbarHeight = kToolbarHeight,
    this.centerCollapsedTitle = true,
    this.appBarActionsBuilder,
    this.canUseTabFooter,
    this.onSharePressed,
    this.shareIcon = Icons.share,
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

  /// Required back policy so the visible and system/browser back surfaces
  /// share one explicit contract.
  final RouteBackPolicy backPolicy;

  /// Initial tab index (defaults to 0)
  final int initialTabIndex;

  /// Optional default footer widget
  /// Individual tabs can override this with their own footer
  final Widget? footer;

  /// Optional gate that decides whether the active tab footer may replace the
  /// screen-level default footer.
  final bool Function(int currentTabIndex)? canUseTabFooter;

  /// Optional widget displayed in the app bar when the hero is collapsed.
  final Widget? collapsedTitle;

  /// Height used by the collapsed/pinned app bar.
  final double collapsedToolbarHeight;

  /// Whether the collapsed title should be centered.
  final bool centerCollapsedTitle;

  /// Optional builder for screen-specific app bar actions that should live in
  /// the same overlay plane as the built-in share action.
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)?
      appBarActionsBuilder;

  /// Optional share handler for surfaces that expose a canonical public share.
  final VoidCallback? onSharePressed;

  /// Optional icon used by the share action when [onSharePressed] is provided.
  final IconData shareIcon;

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
    _scheduleInitialTabActivation(widget.initialTabIndex);
  }

  @override
  void didUpdateWidget(covariant ImmersiveDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tabsChanged = !identical(oldWidget.tabs, widget.tabs) ||
        oldWidget.tabs.length != widget.tabs.length ||
        !listEquals(
          oldWidget.tabs.map((t) => t.title).toList(),
          widget.tabs.map((t) => t.title).toList(),
        );

    if (tabsChanged) {
      _controller.updateTabs(widget.tabs);
    }
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _scheduleInitialTabActivation(widget.initialTabIndex);
    }
  }

  void _scheduleInitialTabActivation(int index) {
    if (index <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.onTabTapped(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const appBarExpandedHeight = 400.0;

    return RouteBackScope(
      backPolicy: widget.backPolicy,
      child: Scaffold(
        // Use LayoutBuilder to get the exact available height for the body
        // This accounts for the Scaffold's bottomNavigationBar (footer) automatically
        body: LayoutBuilder(
          builder: (context, constraints) {
            // The total available height for the NestedScrollView
            final availableHeight = constraints.maxHeight;

            // The height of the pinned header (StatusBar + AppBar + Tabs)
            final pinnedHeaderHeight = MediaQuery.of(context).padding.top +
                widget.collapsedToolbarHeight +
                48.0;
            _controller.updatePinnedHeaderHeight(pinnedHeaderHeight);

            // The minimum height for each tab content to fill the viewport
            // We subtract the pinned header height from the available height
            final minTabHeight = availableHeight - pinnedHeaderHeight;

            return GestureDetector(
              key: const Key('immersiveSwipeSurface'),
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                _controller.onHorizontalSwipeEnd(details.primaryVelocity);
              },
              child: NestedScrollView(
                key: _controller.nestedScrollViewKey,
                controller: _controller.scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: appBarExpandedHeight,
                      toolbarHeight: widget.collapsedToolbarHeight,
                      pinned: true,
                      stretch: true,
                      backgroundColor: colorScheme.surface,
                      title: innerBoxIsScrolled
                          ? widget.collapsedTitle ??
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  key: const Key('immersiveCollapsedTitle'),
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              )
                          : null,
                      centerTitle: widget.centerCollapsedTitle,
                      leading: _buildAppBarActionButton(
                        context: context,
                        icon: Icons.arrow_back,
                        innerBoxIsScrolled: innerBoxIsScrolled,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 4,
                        ),
                        onPressed: widget.backPolicy.handleBack,
                      ),
                      actions: [
                        ...?widget.appBarActionsBuilder?.call(
                          context,
                          innerBoxIsScrolled,
                        ),
                        if (widget.onSharePressed != null)
                          _buildAppBarActionButton(
                            context: context,
                            icon: widget.shareIcon,
                            innerBoxIsScrolled: innerBoxIsScrolled,
                            onPressed: widget.onSharePressed!,
                            key: const Key('immersiveShareAction'),
                          ),
                        const SizedBox(width: 8),
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
              final tabFooter = _controller.tabItems[safeIndex].footer;
              final canUseTabFooter =
                  widget.canUseTabFooter?.call(safeIndex) ?? true;

              return (canUseTabFooter ? tabFooter : null) ??
                  widget.footer ??
                  const SizedBox.shrink();
            }),
      ),
    );
  }

  Widget _buildAppBarActionButton({
    required BuildContext context,
    required IconData icon,
    required bool innerBoxIsScrolled,
    required VoidCallback onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.only(right: 8),
    Key? key,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = innerBoxIsScrolled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : Colors.black.withValues(alpha: 0.28);
    final foregroundColor = _contentColorForBackground(backgroundColor);
    final outlineColor = innerBoxIsScrolled
        ? colorScheme.outlineVariant.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.12);

    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor),
        ),
        child: IconButton(
          key: key,
          icon: Icon(icon, color: foregroundColor),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Color _contentColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}
