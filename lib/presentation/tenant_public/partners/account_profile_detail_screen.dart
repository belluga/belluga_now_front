import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/sharing/account_profile_public_share_payload.dart';
import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_identity_block.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AccountProfileDetailScreen extends StatefulWidget {
  const AccountProfileDetailScreen({
    super.key,
    required this.accountProfile,
    this.directionsAppChooser,
  });

  final AccountProfileModel accountProfile;
  final DirectionsAppChooserContract? directionsAppChooser;

  @override
  State<AccountProfileDetailScreen> createState() =>
      _AccountProfileDetailScreenState();
}

class _AccountProfileDetailScreenState
    extends State<AccountProfileDetailScreen> {
  final AccountProfileDetailController _controller =
      GetIt.I.get<AccountProfileDetailController>();
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();

  @override
  void initState() {
    super.initState();
    _controller.loadResolvedAccountProfile(widget.accountProfile);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamValueBuilder<bool>(
        streamValue: _controller.isLoadingStreamValue,
        builder: (context, isLoading) {
          if (isLoading) {
            return _buildLoadingState();
          }
          return StreamValueBuilder<String>(
            streamValue: _controller.errorMessageStreamValue,
            builder: (context, errorMessage) {
              if (errorMessage.trim().isNotEmpty) {
                return _buildErrorState(errorMessage);
              }
              return StreamValueBuilder<AccountProfileModel?>(
                streamValue: _controller.accountProfileStreamValue,
                onNullWidget: _buildEmptyState(),
                builder: (context, accountProfile) {
                  return StreamValueBuilder<PartnerProfileConfig?>(
                    streamValue: _controller.profileConfigStreamValue,
                    onNullWidget: _buildLoadingState(),
                    builder: (context, config) {
                      final resolvedAccountProfile = accountProfile!;
                      final resolvedConfig = config!;
                      return StreamValueBuilder<Map<ProfileModuleId, Object?>>(
                        streamValue: _controller.moduleDataStreamValue,
                        builder: (context, moduleData) {
                          return StreamValueBuilder<Set<String>>(
                            streamValue: _controller.favoriteIdsStream,
                            builder: (context, favorites) {
                              return StreamValueBuilder<int>(
                                streamValue:
                                    _controller.agendaStatusRevisionStreamValue,
                                builder: (context, _) {
                                  final isFav = favorites
                                      .contains(resolvedAccountProfile.id);
                                  final isFavoritable = _controller
                                      .isFavoritable(resolvedAccountProfile);
                                  final configTabs = _buildTabsFromConfig(
                                    resolvedAccountProfile,
                                    resolvedConfig,
                                    moduleData,
                                    isFav: isFav,
                                    isFavoritable: isFavoritable,
                                  );
                                  final effectiveTabs = configTabs.isEmpty
                                      ? <ImmersiveTabItem>[
                                          _buildFallbackTab(
                                            resolvedAccountProfile,
                                            isFav: isFav,
                                            isFavoritable: isFavoritable,
                                          ),
                                        ]
                                      : configTabs;
                                  return ImmersiveDetailScreen(
                                    heroContent: _buildHero(
                                      resolvedAccountProfile,
                                    ),
                                    title: resolvedAccountProfile.name,
                                    collapsedToolbarHeight: 72,
                                    centerCollapsedTitle: false,
                                    appBarActionsBuilder:
                                        (context, innerBoxIsScrolled) =>
                                            _buildAppBarActions(
                                      context,
                                      innerBoxIsScrolled,
                                      resolvedAccountProfile,
                                      isFav: isFav,
                                      isFavoritable: isFavoritable,
                                    ),
                                    backPolicy:
                                        buildCanonicalCurrentRouteBackPolicy(
                                      context,
                                    ),
                                    onSharePressed: () => unawaited(
                                      _shareAccountProfile(
                                        resolvedAccountProfile,
                                      ),
                                    ),
                                    shareIcon: BooraIcons.share,
                                    tabs: effectiveTabs,
                                    betweenHeroAndTabs: null,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHero(AccountProfileModel accountProfile) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedVisual = _controller.resolvedVisualFor(accountProfile);
    final fallbackHero = _buildHeroFallback(
      colorScheme: colorScheme,
      visual: resolvedVisual.typeVisual,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        resolvedVisual.surfaceImageUrl != null
            ? BellugaNetworkImage(
                resolvedVisual.surfaceImageUrl!,
                fit: BoxFit.cover,
                errorWidget: fallbackHero,
              )
            : fallbackHero,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  colorScheme.surface.withValues(alpha: 0.16),
                  colorScheme.surface.withValues(alpha: 0.9),
                ],
                stops: const <double>[0, 0.62, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: AccountProfileIdentityBlock(
            name: accountProfile.name,
            avatarUrl: resolvedVisual.identityAvatarUrl,
            typeVisual: resolvedVisual.typeVisual,
            identityAvatarKey: const Key('accountProfileHeroIdentityAvatar'),
            typeAvatarKey: const Key('accountProfileHeroTypeAvatar'),
            avatarSize: 56,
            avatarSpacing: 14,
            typeAvatarSize: 28,
            typeAvatarIconSize: 16,
            titleSpacing: 10,
            supportingSpacing: 12,
            titleStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
            titleTrailing: [
              if (accountProfile.isVerified)
                _buildVerifiedBadge(onDarkBackground: true),
            ],
            supporting: _buildHeroSupporting(accountProfile),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    bool innerBoxIsScrolled,
    AccountProfileModel accountProfile, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    if (!isFavoritable) {
      return const <Widget>[];
    }

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = innerBoxIsScrolled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : Colors.black.withValues(alpha: 0.28);
    final foregroundColor = _contentColorForBackground(backgroundColor);
    final iconColor = isFav
        ? (ThemeData.estimateBrightnessForColor(backgroundColor) ==
                Brightness.dark
            ? Colors.red.shade200
            : Colors.red.shade700)
        : foregroundColor;

    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: innerBoxIsScrolled
                  ? colorScheme.outlineVariant.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: IconButton(
            key: const Key('accountProfileFavoriteAction'),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: iconColor,
            ),
            tooltip: isFav ? 'Favoritado' : 'Favoritar',
            onPressed: () => _handleFavoriteTap(accountProfile.id),
          ),
        ),
      ),
    ];
  }

  Widget _buildHeroFallback({
    required ColorScheme colorScheme,
    required ResolvedProfileTypeVisual? visual,
  }) {
    if (visual?.isImage == true && visual?.imageUrl != null) {
      return BellugaNetworkImage(
        visual!.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: _buildDefaultHeroFallback(
          colorScheme: colorScheme,
          visual: null,
        ),
      );
    }

    return _buildDefaultHeroFallback(
      colorScheme: colorScheme,
      visual: visual,
    );
  }

  Widget _buildDefaultHeroFallback({
    required ColorScheme colorScheme,
    required ResolvedProfileTypeVisual? visual,
  }) {
    return Container(
      color: visual?.backgroundColor ?? colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        visual?.iconData ?? Icons.account_circle,
        size: 64,
        color: visual?.iconColor ?? colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildHeroSupporting(AccountProfileModel accountProfile) {
    final children = <Widget>[
      if (accountProfile.distanceMeters != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              _distanceLabelFromMeters(accountProfile.distanceMeters!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      if (accountProfile.tags.isNotEmpty)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: accountProfile.tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    tag.value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
    ];

    if (children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          children[index],
        ],
      ],
    );
  }

  List<ImmersiveTabItem> _buildTabsFromConfig(
    AccountProfileModel accountProfile,
    PartnerProfileConfig config,
    Map<ProfileModuleId, Object?> moduleData, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    final agendaEvents = _agendaEventsFromModuleData(moduleData);
    final locationView = _locationFromModuleData(moduleData);

    final tabs = config.tabs
        .where(
          (tab) => _shouldRenderTab(
            tab,
            agendaEvents: agendaEvents,
            location: locationView,
          ),
        )
        .map(
          (tab) => ImmersiveTabItem(
            title: tab.title,
            content: _buildModules(tab.modules, moduleData),
            footer: _buildTabFooter(
              accountProfile,
              tab,
              location: locationView,
              isFav: isFav,
              isFavoritable: isFavoritable,
            ),
          ),
        )
        .toList();

    tabs.sort(
      (left, right) =>
          _tabOrderRank(left.title).compareTo(_tabOrderRank(right.title)),
    );

    return tabs;
  }

  int _tabOrderRank(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized == 'sobre') {
      return 0;
    }
    if (normalized == 'agenda' || normalized == 'eventos') {
      return 1;
    }
    if (normalized.contains('chegar')) {
      return 2;
    }
    return 100;
  }

  bool _shouldRenderTab(
    ProfileTabConfig tab, {
    required List<PartnerEventView> agendaEvents,
    required PartnerLocationView? location,
  }) {
    final lowerTitle = tab.title.toLowerCase();
    if (lowerTitle.contains('chegar')) {
      return _canRenderLocationSection(location);
    }
    if (lowerTitle.contains('evento') || lowerTitle.contains('agenda')) {
      return agendaEvents.isNotEmpty;
    }
    return true;
  }

  ImmersiveTabItem _buildFallbackTab(
    AccountProfileModel accountProfile, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    return ImmersiveTabItem(
      title: 'Perfil',
      content: _buildNoSectionsFallback(
        accountProfile,
        isFav: isFav,
        isFavoritable: isFavoritable,
      ),
      footer: _buildFallbackFooter(
        accountProfile,
        isFav: isFav,
        isFavoritable: isFavoritable,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingIntent();
  }

  void _checkPendingIntent() {
    final redirectPath = _safeRedirectPath();
    final action = AuthWallTelemetry.consumePendingAction(redirectPath);
    if (action != null && action.actionType == AuthWallActionType.favorite) {
      final partnerId = action.payload?['partnerId'] as String?;
      if (partnerId != null) {
        _controller.toggleFavorite(partnerId);
      }
    }
  }

  void _handleFavoriteTap(String accountProfileId) {
    final redirectPath = _safeRedirectPath();
    if (kIsWeb) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.favorite,
        redirectPath: redirectPath,
        payload: {'partnerId': accountProfileId},
      );
      _safeRouterPushPath(
        buildWebPromotionBoundaryPath(
          redirectPath: redirectPath,
        ),
      );
      return;
    }

    final result = _controller.toggleFavorite(accountProfileId);
    if (result != AccountProfileFavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: redirectPath,
      payload: {'partnerId': accountProfileId},
    );
    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    _safeRouterReplacePath('/auth/login?redirect=$encodedRedirect');
  }

  Future<void> _shareAccountProfile(AccountProfileModel accountProfile) async {
    final slug = accountProfile.slug.trim();
    if (slug.isEmpty) {
      _showStatusMessage(
        'Não foi possível compartilhar ${accountProfile.name}.',
      );
      return;
    }

    final publicUri = _controller.buildTenantPublicUriFromPath(
      '/parceiro/$slug',
    );
    if (publicUri == null) {
      _showStatusMessage(
        'Não foi possível compartilhar ${accountProfile.name}.',
      );
      return;
    }

    final payload = AccountProfilePublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: accountProfile.name,
      profile: accountProfile,
      actorDisplayName: _controller.authenticatedUserDisplayName,
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: payload.message,
          subject: payload.subject,
        ),
      );
    } catch (_) {
      _showStatusMessage(
        'Não foi possível compartilhar ${accountProfile.name}.',
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      key: Key('accountProfileLoadingState'),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const Key('accountProfileEmptyState'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'Perfil não encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esse parceiro não está disponível neste momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      key: const Key('accountProfileErrorState'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              'Não foi possível abrir o perfil',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSectionsFallback(
    AccountProfileModel accountProfile, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeLabel = _controller.typeLabelFor(accountProfile);
    final showFavoriteEmptyState = isFavoritable && !isFav;
    return Padding(
      key: const Key('accountProfileNoSectionsFallback'),
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showFavoriteEmptyState
                  ? 'Favorite para ser avisado das novidades sobre ${accountProfile.name}.'
                  : 'Mais sobre este perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (!showFavoriteEmptyState) ...[
              const SizedBox(height: 12),
              Text(
                'Este $typeLabel ainda não publicou módulos adicionais por aqui. '
                'Novas informações devem aparecer em breve.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge({required bool onDarkBackground}) {
    final background = onDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground =
        onDarkBackground ? Colors.white : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDarkBackground
              ? Colors.white.withValues(alpha: 0.14)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Icon(Icons.verified, size: 16, color: foreground),
    );
  }

  String _safeRedirectPath() {
    try {
      return buildRedirectPathFromRouteMatch(context.routeData.route);
    } catch (_) {
      return '/';
    }
  }

  void _safeRouterPushPath(String path) {
    try {
      context.router.pushPath(path);
    } catch (_) {
      // Tests and non-router surfaces can ignore this safely.
    }
  }

  void _safeRouterReplacePath(String path) {
    try {
      context.router.replacePath(path);
    } catch (_) {
      // Tests and non-router surfaces can ignore this safely.
    }
  }

  List<PartnerEventView> _agendaEventsFromModuleData(
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    final raw = moduleData[ProfileModuleId.agendaList];
    if (raw is List<PartnerEventView>) {
      return raw;
    }
    return const <PartnerEventView>[];
  }

  PartnerLocationView? _locationFromModuleData(
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    final raw = moduleData[ProfileModuleId.locationInfo];
    return raw is PartnerLocationView ? raw : null;
  }

  PartnerEventView? _resolveLiveEvent(List<PartnerEventView> events) {
    for (final event in events) {
      if (_isHappeningNow(event)) {
        return event;
      }
    }
    return null;
  }

  bool _isHappeningNow(PartnerEventView event) {
    final now = DateTime.now();
    final start = event.startDateTime;
    final end = event.endDateTime ?? start.add(const Duration(hours: 3));
    return !now.isBefore(start) && !now.isAfter(end);
  }

  Widget? _buildTabFooter(
    AccountProfileModel accountProfile,
    ProfileTabConfig tab, {
    required PartnerLocationView? location,
    required bool isFav,
    required bool isFavoritable,
  }) {
    final lowerTitle = tab.title.toLowerCase();
    if (lowerTitle.contains('evento') || lowerTitle.contains('agenda')) {
      if (!isFavoritable || isFav) {
        return null;
      }
      return _favoriteFooter(accountProfile);
    }

    if (lowerTitle.contains('chegar') && _canOpenMaps(location)) {
      return _routeFooter(location!);
    }

    return null;
  }

  Widget? _buildFallbackFooter(
    AccountProfileModel accountProfile, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    if (!isFavoritable || isFav) {
      return null;
    }
    return _favoriteFooter(accountProfile);
  }

  Widget _favoriteFooter(AccountProfileModel accountProfile) {
    return _buildFooterShell(
      child: FilledButton.icon(
        key: const Key('accountProfileFavoriteFooterButton'),
        onPressed: () => _handleFavoriteTap(accountProfile.id),
        icon: const Icon(Icons.favorite_border),
        label: const Text('Favoritar'),
        style: _primaryFooterButtonStyle(),
      ),
    );
  }

  Widget _routeFooter(PartnerLocationView location) {
    return _buildFooterShell(
      child: FilledButton.icon(
        key: const Key('accountProfileRouteFooterButton'),
        onPressed: () => _presentDirectionsChooser(location),
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('Traçar rota'),
        style: _primaryFooterButtonStyle(),
      ),
    );
  }

  String _distanceLabelFromMeters(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m de você';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km de você';
  }

  // Placeholder module widgets
  Widget _artistHighlights(List<PartnerEventView>? events) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destaques & Agenda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (events == null || events.isEmpty)
            const Text('Nenhum evento disponível')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: events
                  .take(6)
                  .map(
                    (e) => Container(
                      width: 140,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _eventDateLabel(e),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _productGrid(List<PartnerProductView>? products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: products?.length ?? 0,
        itemBuilder: (context, index) {
          final product = products![index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(product.price),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _agendaList(
    AccountProfileModel accountProfile,
    List<PartnerEventView>? events,
  ) {
    final agenda = events ?? const <PartnerEventView>[];
    if (agenda.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum evento disponível por enquanto.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final featuredEvent = _resolveLiveEvent(agenda);
    final upcomingEvents = agenda
        .where(
          (event) =>
              featuredEvent == null || event.uniqueId != featuredEvent.uniqueId,
        )
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featuredEvent != null) ...[
            Text(
              'Acontecendo Agora',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            _buildAgendaLiveHighlightCard(accountProfile, featuredEvent),
            const SizedBox(height: 28),
          ],
          if (upcomingEvents.isNotEmpty) ...[
            Text(
              'Próximos Eventos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            ...upcomingEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildAgendaEventCard(accountProfile, event),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationInfo(PartnerLocationView? location) {
    final colorScheme = Theme.of(context).colorScheme;
    final distanceLabel = widget.accountProfile.distanceMeters == null
        ? null
        : _distanceLabelFromMeters(widget.accountProfile.distanceMeters!);
    final resolvedAddress = location?.address.trim();
    final hasAddress = resolvedAddress != null && resolvedAddress.isNotEmpty;
    final canOpenProfileMap = _canOpenProfileMap(location);
    final distanceBadgeBackground = Colors.white.withValues(alpha: 0.96);
    final distanceBadgeForeground =
        _contentColorForBackground(distanceBadgeBackground);
    final addressCardBackground = colorScheme.surface.withValues(alpha: 0.95);
    final addressCardForeground =
        _contentColorForBackground(addressCardBackground);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como Chegar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('accountProfileLocationTile'),
            onTap: canOpenProfileMap ? _openProfileMap : null,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildLocationMapCanvas(location),
                  if (distanceLabel != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        key: const Key('accountProfileLocationDistanceBadge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: distanceBadgeBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          distanceLabel,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: distanceBadgeForeground,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: addressCardBackground,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.near_me_outlined,
                              color: _contentColorForBackground(
                                colorScheme.primaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasAddress ? 'Endereço' : 'Ver no mapa',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: addressCardForeground,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                if (hasAddress) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    resolvedAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: addressCardForeground,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canOpenProfileMap)
                            Icon(
                              Icons.map_outlined,
                              color: addressCardForeground,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapCanvas(PartnerLocationView? location) {
    final lat = double.tryParse(location?.lat ?? '');
    final lng = double.tryParse(location?.lng ?? '');
    if (lat == null || lng == null) {
      return _buildMapFallback(location);
    }

    final point = LatLng(lat, lng);
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: FlutterMap(
        key: const Key('accountProfileEmbeddedMapPreview'),
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15,
          minZoom: 15,
          maxZoom: 15,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.none,
            rotationWinGestures: MultiFingerGesture.none,
            cursorKeyboardRotationOptions:
                CursorKeyboardRotationOptions.disabled(),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.belluganow.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 64,
                height: 64,
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      BooraIcons.store_mall_directory,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallback(PartnerLocationView? location) {
    final colorScheme = Theme.of(context).colorScheme;
    final address = location?.address;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                BooraIcons.store_mall_directory,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              address?.isNotEmpty == true ? address! : 'Mapa do local',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileMap() {
    final path = Uri(
      path: '/mapa',
      queryParameters: {
        'poi': 'account_profile:${widget.accountProfile.id}',
      },
    ).toString();
    _safeRouterPushPath(path);
  }

  void _presentDirectionsChooser(PartnerLocationView? location) {
    final target = _directionsTargetFromLocation(location);
    if (target == null) {
      return;
    }
    _directionsAppChooser.present(
      context,
      target: target,
      onStatusMessage: _showStatusMessage,
    );
  }

  bool _canOpenMaps(PartnerLocationView? location) {
    return _directionsTargetFromLocation(location) != null;
  }

  bool _canOpenProfileMap(PartnerLocationView? location) {
    if (location == null) {
      return false;
    }
    return widget.accountProfile.id.trim().isNotEmpty;
  }

  bool _canRenderLocationSection(PartnerLocationView? location) {
    if (location == null) {
      return false;
    }
    return _canOpenMaps(location);
  }

  DirectionsLaunchTarget? _directionsTargetFromLocation(
    PartnerLocationView? location,
  ) {
    if (location == null) {
      return null;
    }
    final latitude = double.tryParse(location.lat ?? '');
    final longitude = double.tryParse(location.lng ?? '');
    final address = location.address.trim();
    if (latitude == null || longitude == null) {
      if (address.isEmpty) {
        return null;
      }
      return DirectionsLaunchTarget(
        destinationName: widget.accountProfile.name,
        address: address,
      );
    }
    return DirectionsLaunchTarget(
      destinationName: widget.accountProfile.name,
      latitude: latitude,
      longitude: longitude,
      address: address.isEmpty ? null : address,
    );
  }

  void _showStatusMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFooterShell({
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }

  ButtonStyle _primaryFooterButtonStyle() {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.primary;
    final foregroundColor = _contentColorForBackground(backgroundColor);
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: const Size.fromHeight(60),
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
    );
  }

  Color _contentColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  Widget _buildAgendaLiveHighlightCard(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final headline = _agendaPrimaryLabel(accountProfile, event);
    final eyebrow = _agendaEyebrowLabel(event);
    final statusWidget = _buildAgendaStatusWidget(
      event: event,
      backgroundColor: colorScheme.secondary.withValues(alpha: 0.3),
      size: 18,
    );
    final statusTint = _agendaStatusTint(
      colorScheme: colorScheme,
      event: event,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('accountProfileAgendaLiveCard_${event.uniqueId}'),
          onTap: () => _safeRouterPushPath('/agenda/evento/${event.slug}'),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildAgendaImage(event),
              ),
              if (statusTint != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: statusTint,
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusWidget != null) ...[
                      statusWidget,
                      const SizedBox(width: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'AO VIVO',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow,
                        key: Key(
                          'accountProfileAgendaLiveEyebrow_${event.uniqueId}',
                        ),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      headline,
                      key: Key(
                          'accountProfileAgendaLiveHeadline_${event.uniqueId}'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                              ),
                    ),
                    if (_agendaCounterparts(accountProfile, event)
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildAgendaCounterpartsLine(
                        accountProfile,
                        event,
                        keyPrefix: 'accountProfileAgendaLiveCounterparts',
                        textColor: Colors.white70,
                        iconColor: Colors.white,
                        chipBackground: Colors.black.withValues(alpha: 0.28),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      key: Key(
                        'accountProfileAgendaLiveSchedule_${event.uniqueId}',
                      ),
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _eventExpandedTimeRangeLabel(event),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (_buildAgendaVenueLine(
                      accountProfile,
                      event,
                      keyPrefix: 'accountProfileAgendaLiveVenue',
                      textColor: Colors.white,
                    )
                        case final venueLine?) ...[
                      const SizedBox(height: 10),
                      venueLine,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaEventCard(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    return UpcomingEventCard(
      data: UpcomingEventCardData(
        imageUri: event.imageUri,
        headline: _agendaPrimaryLabel(accountProfile, event),
        metaLabel: _eventDateLabel(event),
        counterparts: _agendaCounterparts(accountProfile, event)
            .map(
              (counterpart) => (
                label: counterpart.label,
                thumbUrl: counterpart.thumbUrl,
                fallbackIcon: Icons.music_note,
              ),
            )
            .toList(growable: false),
        venueName: _agendaVenueName(event),
        venueDistanceLabel: _controller.distanceLabelFor(accountProfile, event),
        venueAddress: _agendaVenueAddress(event),
      ),
      onTap: () => _safeRouterPushPath('/agenda/evento/${event.slug}'),
      isConfirmed: _controller.isEventConfirmed(event.eventId),
      pendingInvitesCount: _controller.pendingInviteCount(event.eventId),
      statusIconSize: 24,
      keyNamespace: 'accountProfileAgendaCard',
      cardId: event.uniqueId,
    );
  }

  Widget _buildAgendaImage(PartnerEventView event) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUri = event.imageUri;
    if (imageUri == null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.event_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return BellugaNetworkImage(
      imageUri.toString(),
      fit: BoxFit.cover,
      errorWidget: Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }

  String _agendaPrimaryLabel(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    return event.title;
  }

  String? _agendaEyebrowLabel(PartnerEventView event) {
    return event.eventTypeLabel;
  }

  List<_AgendaCounterpart> _agendaCounterparts(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    final counterparts = <_AgendaCounterpart>[];
    final seen = <String>{};

    for (final counterpart in _agendaCounterpartProfiles(
      accountProfile,
      event,
    )) {
      final title = counterpart.title.trim();
      if (title.isEmpty) {
        continue;
      }
      final normalized = _normalizedAgendaIdentity(title);
      if (normalized == null || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      counterparts.add(
        _AgendaCounterpart(
          label: title,
          thumbUrl: counterpart.thumb,
        ),
      );
    }

    return counterparts;
  }

  List<PartnerSupportedEntityView> _agendaCounterpartProfiles(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    return event.counterpartProfiles
        .where(
          (counterpart) => !_agendaMatchesHost(
            accountProfile,
            candidateId: counterpart.id,
            candidateTitle: counterpart.title,
          ),
        )
        .toList(growable: false);
  }

  bool _agendaMatchesHost(
    AccountProfileModel accountProfile, {
    String? candidateId,
    String? candidateTitle,
  }) {
    final normalizedCandidateId = candidateId?.trim();
    if (normalizedCandidateId != null &&
        normalizedCandidateId.isNotEmpty &&
        normalizedCandidateId == accountProfile.id) {
      return true;
    }

    final normalizedCandidateTitle = _normalizedAgendaIdentity(candidateTitle);
    if (normalizedCandidateTitle == null) {
      return false;
    }

    return normalizedCandidateTitle ==
        _normalizedAgendaIdentity(accountProfile.name);
  }

  String? _normalizedAgendaIdentity(String? raw) {
    final trimmed = raw?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Widget _buildAgendaCounterpartsLine(
    AccountProfileModel accountProfile,
    PartnerEventView event, {
    required String keyPrefix,
    required Color textColor,
    required Color iconColor,
    required Color chipBackground,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        );
    final counterparts = _agendaCounterparts(accountProfile, event);
    return Wrap(
      key: Key('${keyPrefix}_${event.uniqueId}'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: counterparts
          .asMap()
          .entries
          .map(
            (entry) => _buildAgendaCounterpartBadge(
              entry.value,
              labelStyle: textStyle,
              iconColor: iconColor,
              chipBackground: chipBackground,
              key: Key('$keyPrefix${entry.key}_${event.uniqueId}'),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildAgendaCounterpartBadge(
    _AgendaCounterpart counterpart, {
    required TextStyle? labelStyle,
    required Color iconColor,
    required Color chipBackground,
    required Key key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAgendaCounterpartVisual(counterpart, iconColor: iconColor),
          const SizedBox(width: 6),
          Text(counterpart.label, style: labelStyle),
        ],
      ),
    );
  }

  Widget? _buildAgendaVenueLine(
    AccountProfileModel accountProfile,
    PartnerEventView event, {
    required String keyPrefix,
    required Color textColor,
  }) {
    final venueName = _agendaVenueName(event);
    if (venueName == null) {
      return null;
    }
    final distanceLabel = _controller.distanceLabelFor(accountProfile, event);
    final address = _agendaVenueAddress(event);
    final buffer = StringBuffer(venueName);
    if (distanceLabel != null && distanceLabel.trim().isNotEmpty) {
      buffer.write(' (${distanceLabel.trim()})');
    }
    if (address != null && address.trim().isNotEmpty) {
      buffer.write(' - ${address.trim()}');
    }

    return Row(
      key: Key('${keyPrefix}_${event.uniqueId}'),
      children: [
        Icon(Icons.place_outlined, size: 16, color: textColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            buffer.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  String? _agendaVenueName(PartnerEventView event) {
    final venueTitle = event.venueTitle?.trim();
    if (venueTitle != null && venueTitle.isNotEmpty) {
      return venueTitle;
    }
    final fallback = event.location.trim();
    if (fallback.isEmpty) {
      return null;
    }
    return fallback;
  }

  String? _agendaVenueAddress(PartnerEventView event) {
    return null;
  }

  Widget _buildAgendaCounterpartVisual(
    _AgendaCounterpart counterpart, {
    required Color iconColor,
  }) {
    final fallbackIcon = Icons.music_note;
    if (counterpart.thumbUrl case final thumbUrl?) {
      return ClipOval(
        child: BellugaNetworkImage(
          thumbUrl,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          errorWidget: Icon(
            fallbackIcon,
            size: 16,
            color: iconColor,
          ),
        ),
      );
    }

    return Icon(
      fallbackIcon,
      size: 16,
      color: iconColor,
    );
  }

  String _eventDateLabel(PartnerEventView event) {
    final start = event.startDateTime;
    final weekday = DateFormat.E().format(start);
    final day = start.day.toString().padLeft(2, '0');
    return '$weekday, $day • ${start.timeLabel}'.toUpperCase();
  }

  String _eventExpandedTimeRangeLabel(PartnerEventView event) {
    final start = event.startDateTime;
    final end = event.endDateTime ?? start.add(const Duration(hours: 3));
    final startWeekday = DateFormat.E().format(start).toUpperCase();
    final startDay = start.day.toString().padLeft(2, '0');
    final endWeekday = DateFormat.E().format(end).toUpperCase();
    final endDay = end.day.toString().padLeft(2, '0');
    return '$startWeekday, $startDay • ${start.timeLabel} - '
        '$endWeekday, $endDay • ${end.timeLabel}';
  }

  Color? _agendaStatusTint({
    required ColorScheme colorScheme,
    required PartnerEventView event,
  }) {
    if (_controller.isEventConfirmed(event.eventId)) {
      return colorScheme.primary.withValues(alpha: 0.08);
    }
    if (_controller.pendingInviteCount(event.eventId) > 0) {
      return colorScheme.secondary.withValues(alpha: 0.08);
    }
    return null;
  }

  Widget? _buildAgendaStatusWidget({
    required PartnerEventView event,
    required Color backgroundColor,
    required double size,
  }) {
    final isConfirmed = _controller.isEventConfirmed(event.eventId);
    final pendingInvitesCount = _controller.pendingInviteCount(event.eventId);
    if (!isConfirmed && pendingInvitesCount == 0) {
      return null;
    }
    return InviteStatusIcon(
      isConfirmed: isConfirmed,
      pendingInvitesCount: pendingInvitesCount,
      size: size,
      backgroundColor: backgroundColor,
    );
  }

  Widget _experienceCards(List<PartnerExperienceView>? experiences) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: experiences == null || experiences.isEmpty
          ? const Text('Nenhuma experiência cadastrada')
          : Column(
              children: experiences
                  .map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.explore),
                        title: Text(e.title),
                        subtitle: Text('${e.duration} • ${e.price}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _faqBlock(List<PartnerFaqView>? faq) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: faq == null || faq.isEmpty
          ? const Text('Nenhuma FAQ disponível')
          : ExpansionPanelList.radio(
              children: faq
                  .asMap()
                  .entries
                  .map(
                    (entry) => ExpansionPanelRadio(
                      value: entry.key,
                      headerBuilder: (context, _) =>
                          ListTile(title: Text(entry.value.question)),
                      body: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(entry.value.answer),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _videoGallery(List<PartnerMediaView>? videos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: videos == null || videos.isEmpty
          ? const Text('Nenhum conteúdo no acervo')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: videos
                  .map(
                    (v) => Container(
                      width: 160,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        image: v.url.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(v.url),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: const Icon(Icons.play_arrow),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _externalLinks(List<PartnerLinkView>? links) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: links == null || links.isEmpty
          ? const Text('Nenhum link externo')
          : Column(
              children: links
                  .map(
                    (l) => Card(
                      child: ListTile(
                        leading: Icon(
                            l.icon == 'pix' ? Icons.pix : Icons.link_outlined),
                        title: Text(l.title),
                        subtitle: Text(l.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _photoGrid(List<PartnerMediaView>? photos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: photos == null || photos.isEmpty
          ? const Text('Nenhuma mídia')
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                    image: photo.url.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photo.url),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _affinityCarousel(List<PartnerRecommendationView>? recommendations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recomendações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (recommendations == null || recommendations.isEmpty)
            const Text('Nenhuma recomendação disponível')
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(rec.title),
                        Text(
                          rec.type,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _musicPlayer(List<PartnerMediaView>? tracks) {
    final track = tracks != null && tracks.isNotEmpty ? tracks.first : null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill),
          title: Text(track?.title ?? 'Player indisponível no MVP'),
          subtitle: Text(track?.url ?? ''),
          trailing: const Icon(Icons.block),
        ),
      ),
    );
  }

  Widget _supportedEntities(
      String title, List<PartnerSupportedEntityView>? data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (data == null || data.isEmpty)
            const Text('Nenhum perfil apoiado')
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entity = data[index];
                  return Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: entity.thumb != null
                              ? BellugaNetworkImage(
                                  entity.thumb!,
                                  fit: BoxFit.cover,
                                  errorWidget: const SizedBox(),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(entity.title),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _sponsorBanner(String? sponsor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.handshake),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Oferecimento: ${sponsor ?? 'Parceiro local'}')),
          ],
        ),
      ),
    );
  }

  Widget _richTextBlock(String title, String body) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Html(
            data: body,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                color: colorScheme.onSurfaceVariant,
                fontSize: FontSize(
                  Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
                ),
                lineHeight: const LineHeight(1.45),
              ),
              'p': Style(
                margin: Margins.only(bottom: 12),
              ),
              'strong': Style(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              'br': Style(
                display: Display.block,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModules(
    List<ProfileModuleConfig> modules,
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: modules.map((m) => _buildModule(m, moduleData[m.id])).toList(),
    );
  }

  Widget _buildModule(ProfileModuleConfig module, dynamic data) {
    switch (module.id) {
      case ProfileModuleId.socialScore:
        return const SizedBox.shrink();
      case ProfileModuleId.agendaCarousel:
        return _artistHighlights(
          data is List<PartnerEventView> ? data : null,
        );
      case ProfileModuleId.agendaList:
        return _agendaList(
          widget.accountProfile,
          data is List<PartnerEventView> ? data : null,
        );
      case ProfileModuleId.musicPlayer:
        return _musicPlayer(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.productGrid:
        return _productGrid(
          data is List<PartnerProductView> ? data : null,
        );
      case ProfileModuleId.photoGallery:
        return _photoGrid(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.videoGallery:
        return _videoGallery(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.experienceCards:
        return _experienceCards(
          data is List<PartnerExperienceView> ? data : null,
        );
      case ProfileModuleId.affinityCarousels:
        return _affinityCarousel(
          data is List<PartnerRecommendationView> ? data : null,
        );
      case ProfileModuleId.supportedEntities:
        return _supportedEntities(
          module.title ?? 'Quem apoiamos',
          data is List<PartnerSupportedEntityView> ? data : null,
        );
      case ProfileModuleId.richText:
        return _richTextBlock(
          module.title ?? 'Sobre',
          data is String
              ? data
              : 'Conteúdo institucional e história do perfil.',
        );
      case ProfileModuleId.locationInfo:
        return _locationInfo(data as PartnerLocationView?);
      case ProfileModuleId.externalLinks:
        return _externalLinks(
          data is List<PartnerLinkView> ? data : null,
        );
      case ProfileModuleId.faq:
        return _faqBlock(
          data is List<PartnerFaqView> ? data : null,
        );
      case ProfileModuleId.sponsorBanner:
        return _sponsorBanner(data is String ? data : null);
    }
  }
}

class _AgendaCounterpart {
  const _AgendaCounterpart({
    required this.label,
    this.thumbUrl,
  });

  final String label;
  final String? thumbUrl;
}
