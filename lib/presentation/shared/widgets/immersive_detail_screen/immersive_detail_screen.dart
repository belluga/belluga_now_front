import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/controllers/immersive_detail_screen_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_hero_action.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_header_delegate.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef ImmersiveHeroContentBuilder = Widget Function(
  BuildContext context,
  ValueChanged<int> activateTab,
);

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
    this.heroContent,
    this.heroContentBuilder,
    this.heroViewportHeightFactor = 0.5,
    required this.title,
    required this.tabs,
    required this.backPolicy,
    this.betweenHeroAndTabs,
    this.initialTabIndex = 0,
    this.footer,
    this.collapsedTitle,
    this.collapsedToolbarHeight = kToolbarHeight,
    this.centerCollapsedTitle = true,
    this.heroActions = const <ImmersiveHeroAction>[],
    this.appBarActionsBuilder,
    this.canUseTabFooter,
    this.onSharePressed,
    this.shareIcon = Icons.share,
    this.isShareLoading = false,
    super.key,
  })  : assert(
          heroContent != null || heroContentBuilder != null,
          'Either heroContent or heroContentBuilder must be provided.',
        ),
        assert(
          heroViewportHeightFactor > 0 && heroViewportHeightFactor <= 1,
          'heroViewportHeightFactor must be greater than 0 and at most 1.',
        );

  /// Widget displayed in the hero area (typically an image or custom content)
  final Widget? heroContent;

  /// Optional hero builder for hero content that needs to activate one of the
  /// configured tabs from an in-page affordance.
  final ImmersiveHeroContentBuilder? heroContentBuilder;

  /// Fraction of the viewport height used by the expanded hero.
  final double heroViewportHeightFactor;

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

  /// Canonical action set for the immersive hero.
  ///
  /// When the hero is expanded, actions are shown as a vertical rail over the
  /// hero. When collapsed, the primary action is exposed directly and the
  /// secondary actions move under a "more" button.
  final List<ImmersiveHeroAction> heroActions;

  /// Optional builder for screen-specific app bar actions that should live in
  /// the same overlay plane as the built-in share action.
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)?
      appBarActionsBuilder;

  /// Optional share handler for surfaces that expose a canonical public share.
  final VoidCallback? onSharePressed;

  /// Optional icon used by the share action when [onSharePressed] is provided.
  final IconData shareIcon;

  /// Whether the canonical share action is currently generating its payload.
  final bool isShareLoading;

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
    _scheduleTabActivation(index);
  }

  void _scheduleTabActivation(int index) {
    if (index < 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.onTabTapped(index);
    });
  }

  void _activateTab(int index) {
    if (index < 0) {
      return;
    }
    _controller.onTabTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final requestedHeroHeight =
        mediaQuery.size.height * widget.heroViewportHeightFactor;
    final minimumHeroHeight =
        mediaQuery.padding.top + widget.collapsedToolbarHeight;
    final appBarExpandedHeight = requestedHeroHeight < minimumHeroHeight
        ? minimumHeroHeight
        : requestedHeroHeight;
    final heroActions = _resolveHeroActions();

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
                final primaryVelocity = details.primaryVelocity;
                if (primaryVelocity == null) {
                  return;
                }
                if (_handleActiveTabHorizontalSwipe(primaryVelocity)) {
                  return;
                }
                _controller.onHorizontalSwipeEnd(primaryVelocity);
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
                        tooltip: 'Voltar',
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 4,
                        ),
                        onPressed: widget.backPolicy.handleBack,
                      ),
                      actions: [
                        if (innerBoxIsScrolled)
                          ..._buildCollapsedHeroActions(
                            context: context,
                            actions: heroActions,
                            innerBoxIsScrolled: innerBoxIsScrolled,
                          ),
                        ...?widget.appBarActionsBuilder?.call(
                          context,
                          innerBoxIsScrolled,
                        ),
                        const SizedBox(width: 8),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.heroContentBuilder
                                    ?.call(context, _activateTab) ??
                                widget.heroContent!,
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
                            if (heroActions.isNotEmpty && !innerBoxIsScrolled)
                              Positioned(
                                top: mediaQuery.padding.top + 12,
                                right: 12,
                                child: _buildExpandedHeroActionRail(
                                  context: context,
                                  actions: heroActions,
                                  innerBoxIsScrolled: innerBoxIsScrolled,
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

  List<ImmersiveHeroAction> _resolveHeroActions() {
    if (widget.heroActions.isNotEmpty) {
      return widget.heroActions;
    }

    final onSharePressed = widget.onSharePressed;
    if (onSharePressed == null) {
      return const <ImmersiveHeroAction>[];
    }

    return <ImmersiveHeroAction>[
      ImmersiveHeroAction(
        key: const Key('immersiveShareAction'),
        label: 'Compartilhar',
        icon: widget.shareIcon,
        isPrimary: true,
        isLoading: widget.isShareLoading,
        onPressed: widget.isShareLoading ? null : onSharePressed,
      ),
    ];
  }

  Widget _buildExpandedHeroActionRail({
    required BuildContext context,
    required List<ImmersiveHeroAction> actions,
    required bool innerBoxIsScrolled,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final action in actions)
          _buildHeroActionButton(
            context: context,
            action: action,
            innerBoxIsScrolled: innerBoxIsScrolled,
            padding: const EdgeInsets.only(bottom: 10),
          ),
      ],
    );
  }

  List<Widget> _buildCollapsedHeroActions({
    required BuildContext context,
    required List<ImmersiveHeroAction> actions,
    required bool innerBoxIsScrolled,
  }) {
    final primaryAction = _primaryHeroAction(actions);
    if (primaryAction == null) {
      return const <Widget>[];
    }

    final secondaryActions = actions
        .where((action) => action.key != primaryAction.key)
        .toList(growable: false);

    return <Widget>[
      _buildHeroActionButton(
        context: context,
        action: primaryAction,
        innerBoxIsScrolled: innerBoxIsScrolled,
      ),
      if (secondaryActions.isNotEmpty)
        _buildHeroMoreActionButton(
          context: context,
          actions: secondaryActions,
          innerBoxIsScrolled: innerBoxIsScrolled,
        ),
    ];
  }

  ImmersiveHeroAction? _primaryHeroAction(List<ImmersiveHeroAction> actions) {
    if (actions.isEmpty) {
      return null;
    }
    for (final action in actions) {
      if (action.isPrimary) {
        return action;
      }
    }
    return actions.first;
  }

  Widget _buildHeroActionButton({
    required BuildContext context,
    required ImmersiveHeroAction action,
    required bool innerBoxIsScrolled,
    EdgeInsetsGeometry padding = const EdgeInsets.only(right: 8),
  }) {
    return _buildAppBarActionButton(
      context: context,
      icon: action.resolvedIcon,
      innerBoxIsScrolled: innerBoxIsScrolled,
      tooltip: action.label,
      foregroundColor: action.resolvedForegroundColor,
      iconWidget: action.isLoading
          ? SizedBox(
              key: _loadingKeyFor(action),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _actionForegroundColor(
                    context: context,
                    innerBoxIsScrolled: innerBoxIsScrolled,
                    override: action.resolvedForegroundColor,
                  ),
                ),
              ),
            )
          : null,
      onPressed: action.isLoading ? null : action.onPressed,
      key: action.key,
      padding: padding,
    );
  }

  Widget _buildHeroMoreActionButton({
    required BuildContext context,
    required List<ImmersiveHeroAction> actions,
    required bool innerBoxIsScrolled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = _actionBackgroundColor(
      colorScheme: colorScheme,
      innerBoxIsScrolled: innerBoxIsScrolled,
    );
    final foregroundColor = _contentColorForBackground(backgroundColor);
    final outlineColor = _actionOutlineColor(
      colorScheme: colorScheme,
      innerBoxIsScrolled: innerBoxIsScrolled,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor),
        ),
        child: PopupMenuButton<ImmersiveHeroAction>(
          key: const Key('immersiveHeroMoreAction'),
          tooltip: 'Mais ações',
          icon: Icon(Icons.more_horiz_rounded, color: foregroundColor),
          onSelected: (action) {
            if (action.isLoading) {
              return;
            }
            action.onPressed?.call();
          },
          itemBuilder: (context) {
            return actions
                .map(
                  (action) => PopupMenuItem<ImmersiveHeroAction>(
                    value: action,
                    enabled: action.onPressed != null && !action.isLoading,
                    child: _buildHeroActionMenuItem(context, action),
                  ),
                )
                .toList(growable: false);
          },
        ),
      ),
    );
  }

  Widget _buildHeroActionMenuItem(
    BuildContext context,
    ImmersiveHeroAction action,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        action.resolvedForegroundColor ?? colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        action.isLoading
            ? SizedBox(
                key: _loadingKeyFor(action),
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Icon(action.resolvedIcon, size: 20, color: foregroundColor),
        const SizedBox(width: 12),
        Text(action.label),
      ],
    );
  }

  Key _loadingKeyFor(ImmersiveHeroAction action) {
    if (action.key == const Key('immersiveShareAction')) {
      return const Key('immersiveShareActionLoading');
    }
    return ValueKey('${action.key}Loading');
  }

  Widget _buildAppBarActionButton({
    required BuildContext context,
    IconData? icon,
    required bool innerBoxIsScrolled,
    required VoidCallback? onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.only(right: 8),
    Widget? iconWidget,
    String? tooltip,
    Key? key,
    Color? foregroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = _actionBackgroundColor(
      colorScheme: colorScheme,
      innerBoxIsScrolled: innerBoxIsScrolled,
    );
    final effectiveForegroundColor =
        foregroundColor ?? _contentColorForBackground(backgroundColor);
    final outlineColor = _actionOutlineColor(
      colorScheme: colorScheme,
      innerBoxIsScrolled: innerBoxIsScrolled,
    );

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
          tooltip: tooltip,
          icon: iconWidget ?? Icon(icon, color: effectiveForegroundColor),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Color _actionBackgroundColor({
    required ColorScheme colorScheme,
    required bool innerBoxIsScrolled,
  }) {
    return innerBoxIsScrolled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : Colors.black.withValues(alpha: 0.28);
  }

  Color _actionOutlineColor({
    required ColorScheme colorScheme,
    required bool innerBoxIsScrolled,
  }) {
    return innerBoxIsScrolled
        ? colorScheme.outlineVariant.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.12);
  }

  Color _actionForegroundColor({
    required BuildContext context,
    required bool innerBoxIsScrolled,
    Color? override,
  }) {
    if (override != null) {
      return override;
    }
    final colorScheme = Theme.of(context).colorScheme;
    return _contentColorForBackground(
      _actionBackgroundColor(
        colorScheme: colorScheme,
        innerBoxIsScrolled: innerBoxIsScrolled,
      ),
    );
  }

  Color _contentColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  bool _handleActiveTabHorizontalSwipe(double primaryVelocity) {
    if (widget.tabs.isEmpty) {
      return false;
    }
    final safeIndex = _controller.currentTabIndexStreamValue.value.clamp(
      0,
      widget.tabs.length - 1,
    );
    final handler = widget.tabs[safeIndex].onHorizontalSwipeEnd;
    if (handler == null) {
      return false;
    }

    return handler(
      direction: primaryVelocity < 0
          ? ImmersiveHorizontalSwipeDirection.forward
          : ImmersiveHorizontalSwipeDirection.backward,
      activateTab: _activateTab,
      currentTabIndex: safeIndex,
    );
  }
}
