import 'package:belluga_now/presentation/common/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_header_delegate.dart';
import 'package:flutter/material.dart';

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
  late ScrollController _scrollController;
  int _currentTabIndex = 0;
  bool _isManualScrolling = false;
  double _contentAreaHeight = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Force rebuild after first frame to ensure content area height is calculated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateContentAreaHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const appBarExpandedHeight = 400.0;
    const tabBarHeight = 48.0;
    final appBarPinnedHeight = kToolbarHeight + topPadding;

    // Calculate current AppBar height based on scroll position (gradual transition)
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    final collapseThreshold = appBarExpandedHeight - appBarPinnedHeight;

    // Current AppBar height shrinks gradually from expanded to pinned
    final currentAppBarHeight = scrollOffset >= collapseThreshold
        ? appBarPinnedHeight
        : appBarExpandedHeight - scrollOffset.clamp(0.0, collapseThreshold);

    // Footer height (approximate, or 0 if no footer)
    final footerHeight = widget.footer != null ? 80.0 : 0.0;

    // Available height = screen - appBar - tabs - footer - bottom padding
    return screenHeight -
        currentAppBarHeight -
        tabBarHeight -
        footerHeight -
        bottomPadding;
  }

  void _onScroll() {
    // Don't interfere if user manually tapped a tab
    if (_isManualScrolling) return;

    final scrollOffset = _scrollController.offset;

    final topPadding = MediaQuery.of(context).padding.top;

    // Constants matching the UI
    const appBarExpandedHeight = 400.0;
    final appBarPinnedHeight = kToolbarHeight + topPadding;

    // Calculate current content area height
    final newContentAreaHeight = _calculateContentAreaHeight(context);

    // Check if anything changed that requires rebuild
    bool needsRebuild = false;

    // Update content area height (changes gradually as AppBar collapses)
    if (_contentAreaHeight != newContentAreaHeight) {
      _contentAreaHeight = newContentAreaHeight;
      needsRebuild = true;
    }

    // Calculate which section is >20% visible
    final baseOffset = appBarExpandedHeight - appBarPinnedHeight;
    double relativeOffset = scrollOffset - baseOffset;

    int newIndex = 0;
    if (relativeOffset >= 0 && _contentAreaHeight > 0) {
      // Each section has minHeight = contentAreaHeight
      // Switch when 80% of current section has scrolled away (= 20% of next section visible)
      final sectionIndex = (relativeOffset / _contentAreaHeight).floor();
      final offsetInSection = relativeOffset % _contentAreaHeight;
      final percentageIntoSection = offsetInSection / _contentAreaHeight;

      if (percentageIntoSection >= 0.8) {
        // 80% of current section scrolled away, switch to next
        newIndex = sectionIndex + 1;
      } else {
        newIndex = sectionIndex;
      }
    }

    final clampedIndex = newIndex.clamp(0, widget.tabs.length - 1);

    if (clampedIndex != _currentTabIndex) {
      _currentTabIndex = clampedIndex;
      needsRebuild = true;
    }

    // Only call setState if something actually changed
    if (needsRebuild) {
      setState(() {});
    }
  }

  void _scrollToSection(int index, double contentHeight) {
    final topPadding = MediaQuery.of(context).padding.top;

    const appBarExpandedHeight = 400.0;
    final appBarPinnedHeight = kToolbarHeight + topPadding;

    // Collapse threshold - scroll position where AppBar is fully collapsed
    final collapseThreshold = appBarExpandedHeight - appBarPinnedHeight;

    // Target offset: collapse AppBar fully + scroll to tab's content
    // We use the passed contentHeight (which should be the max/collapsed height)
    final targetOffset = collapseThreshold + (index * contentHeight);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onTabTapped(int index) {
    // Calculate max content area height (when AppBar is collapsed)
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final appBarPinnedHeight = kToolbarHeight + topPadding;
    const tabBarHeight = 48.0;
    final footerHeight = widget.footer != null ? 80.0 : 0.0;

    final maxContentAreaHeight = screenHeight -
        appBarPinnedHeight -
        tabBarHeight -
        footerHeight -
        bottomPadding;

    setState(() {
      _currentTabIndex = index;
      _isManualScrolling = true; // Set flag before scrolling
      _contentAreaHeight = maxContentAreaHeight; // Force max height immediately
    });

    _scrollToSection(index, maxContentAreaHeight);

    // Reset flag after animation completes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get active footer (tab-specific or default)
    final activeFooter = widget.tabs[_currentTabIndex].footer ?? widget.footer;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Immersive Hero with SliverAppBar
              Builder(
                builder: (context) {
                  // Calculate collapsed state for UI styling
                  final scrollOffset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0;
                  final topPadding = MediaQuery.of(context).padding.top;
                  const appBarExpandedHeight = 400.0;
                  final appBarPinnedHeight = kToolbarHeight + topPadding;
                  final isCollapsed = scrollOffset >=
                      (appBarExpandedHeight - appBarPinnedHeight);

                  return SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                      // Use theme color with scrim for visibility
                      color: isCollapsed ? colorScheme.onSurface : Colors.white,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // TODO: Share functionality
                        },
                        color:
                            isCollapsed ? colorScheme.onSurface : Colors.white,
                      ),
                    ],
                    // Title appears when collapsed
                    title: isCollapsed
                        ? Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          )
                        : null,
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
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      collapseMode: CollapseMode.parallax,
                    ),
                  );
                },
              ),

              // Optional content between hero and tabs
              if (widget.betweenHeroAndTabs != null)
                SliverToBoxAdapter(
                  child: widget.betweenHeroAndTabs,
                ),

              // Sticky tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: ImmersiveHeaderDelegate(
                  tabs: widget.tabs.map((tab) => tab.title).toList(),
                  currentTabIndex: _currentTabIndex,
                  onTabTapped: _onTabTapped,
                ),
              ),

              // Expanded Content Area - dynamically sized
              SliverToBoxAdapter(
                child: Column(
                  children: widget.tabs.map((tab) {
                    final minHeight = _contentAreaHeight > 0
                        ? _contentAreaHeight
                        : MediaQuery.of(context).size.height * 0.6;

                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: tab.content,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          // Dynamic footer
          if (activeFooter != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: activeFooter,
            ),
        ],
      ),
    );
  }
}
