import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/application/extensions/compute_on_color.dart';
import 'package:belluga_now/application/sharing/account_profile_public_share_payload.dart';
import 'package:belluga_now/application/rich_text/account_profile_rich_text_block.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/presentation/shared/favorites/account_profile_favorite_auth_gate.dart';
import 'package:belluga_now/presentation/shared/sharing/public_share_launcher.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_identity_block.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_common_tabs.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_hero_action.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/tabs/immersive_directions_section.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AccountProfileDetailScreen extends StatefulWidget {
  const AccountProfileDetailScreen({
    super.key,
    required this.accountProfile,
    this.directionsAppChooser,
    this.shareLauncher,
    this.externalUrlLauncher,
    this.isWebRuntime = kIsWeb,
  });

  final AccountProfileModel accountProfile;
  final DirectionsAppChooserContract? directionsAppChooser;
  final SystemShareLauncher? shareLauncher;
  final ExternalUrlLauncher? externalUrlLauncher;
  final bool isWebRuntime;

  @override
  State<AccountProfileDetailScreen> createState() =>
      _AccountProfileDetailScreenState();
}

class _AccountProfileDetailScreenState
    extends State<AccountProfileDetailScreen> {
  late final AccountProfileDetailController _controller;
  bool _pendingIntentChecked = false;
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();

  @override
  void initState() {
    super.initState();
    _controller = RouteInstanceScope.read<AccountProfileDetailController>(
      context,
    );
    unawaited(_controller.loadResolvedAccountProfile(widget.accountProfile));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pendingIntentChecked) {
      return;
    }
    _pendingIntentChecked = true;
    _checkPendingIntent();
  }

  @override
  void didUpdateWidget(AccountProfileDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountProfile.id != widget.accountProfile.id ||
        oldWidget.accountProfile.slug != widget.accountProfile.slug) {
      unawaited(_controller.loadResolvedAccountProfile(widget.accountProfile));
    }
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
              return StreamValueBuilder(
                streamValue: _controller.detailStateStreamValue,
                builder: (context, detailState) {
                  final accountProfile = detailState.accountProfile;
                  if (accountProfile == null) {
                    return _buildEmptyState();
                  }
                  return StreamValueBuilder<PartnerProfileConfig?>(
                    streamValue: _controller.profileConfigStreamValue,
                    onNullWidget: _buildLoadingState(),
                    builder: (context, config) {
                      final resolvedAccountProfile = accountProfile;
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
                                  return StreamValueBuilder<
                                    ProximityPreference?
                                  >(
                                    streamValue: _controller
                                        .proximityPreferenceStreamValue,
                                    builder: (context, _) {
                                      final isFav = favorites.contains(
                                        resolvedAccountProfile.id,
                                      );
                                      final isFavoritable = _controller
                                          .isFavoritable(
                                            resolvedAccountProfile,
                                          );
                                      final configTabs = _buildTabsFromConfig(
                                        resolvedAccountProfile,
                                        resolvedConfig,
                                        moduleData,
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
                                        heroViewportHeightFactor: 0.5,
                                        title: resolvedAccountProfile.name,
                                        collapsedTitle: _buildCollapsedTitle(
                                          resolvedAccountProfile,
                                        ),
                                        collapsedToolbarHeight: 72,
                                        centerCollapsedTitle: false,
                                        heroActions: _buildHeroActions(
                                          resolvedAccountProfile,
                                          isFav: isFav,
                                          isFavoritable: isFavoritable,
                                        ),
                                        footer: _buildFavoriteFooterIfAvailable(
                                          resolvedAccountProfile,
                                          isFav: isFav,
                                          isFavoritable: isFavoritable,
                                        ),
                                        floatingActionButton:
                                            _buildContactBubbleFloatingActionButton(
                                              resolvedAccountProfile,
                                            ),
                                        backPolicy:
                                            buildCanonicalCurrentRouteBackPolicy(
                                              context,
                                            ),
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

    return ColoredBox(
      color: colorScheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          resolvedVisual.surfaceImageUrl != null
              ? BellugaNetworkImage(
                  resolvedVisual.surfaceImageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: fallbackHero,
                )
              : fallbackHero,
          Positioned.fill(
            child: DecoratedBox(
              key: const Key('accountProfileHeroFadeGradient'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    colorScheme.surface.withValues(alpha: 0.06),
                    colorScheme.surface.withValues(alpha: 0.22),
                    colorScheme.surface.withValues(alpha: 0.48),
                    colorScheme.surface.withValues(alpha: 0.72),
                    colorScheme.surface.withValues(alpha: 0.9),
                    colorScheme.surface,
                  ],
                  stops: const <double>[0, 0.16, 0.32, 0.48, 0.64, 0.8, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildHeroSurfaceSummary(accountProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSurfaceSummary(AccountProfileModel accountProfile) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedVisual = _controller.resolvedVisualFor(accountProfile);

    return KeyedSubtree(
      key: const Key('accountProfileHeroSurfaceSummary'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
          titleTrailing: [
            if (accountProfile.isVerified)
              _buildVerifiedBadge(onDarkBackground: false),
          ],
          supporting: _buildHeroSupporting(accountProfile),
        ),
      ),
    );
  }

  Widget _buildCollapsedTitle(AccountProfileModel accountProfile) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        key: const Key('immersiveCollapsedTitle'),
        accountProfile.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  List<ImmersiveHeroAction> _buildHeroActions(
    AccountProfileModel accountProfile, {
    required bool isFav,
    required bool isFavoritable,
  }) {
    return <ImmersiveHeroAction>[
      if (isFavoritable)
        ImmersiveHeroAction(
          key: const Key('accountProfileFavoriteAction'),
          label: isFav ? 'Perfil favoritado' : 'Favoritar perfil',
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          isPrimary: true,
          isActive: isFav,
          activeForegroundColor: Colors.red.shade400,
          onPressed: () => _handleFavoriteTap(accountProfile.id),
        ),
      ImmersiveHeroAction(
        key: const Key('accountProfileShareAction'),
        label: 'Compartilhar',
        icon: BooraIcons.share,
        isPrimary: !isFavoritable,
        onPressed: () => unawaited(_shareAccountProfile(accountProfile)),
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

    return _buildDefaultHeroFallback(colorScheme: colorScheme, visual: visual);
  }

  Widget _buildDefaultHeroFallback({
    required ColorScheme colorScheme,
    required ResolvedProfileTypeVisual? visual,
  }) {
    return Container(
      key: const Key('accountProfileHeroDefaultFallback'),
      color: visual?.backgroundColor ?? colorScheme.surfaceContainerHighest,
      alignment: const Alignment(0, -0.62),
      child: Icon(
        visual?.iconData ?? Icons.account_circle,
        size: 64,
        color: visual?.iconColor ?? colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildHeroSupporting(AccountProfileModel accountProfile) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipBackground = colorScheme.surfaceContainerHighest;
    final chipForeground = chipBackground.computeIconColor(
      context,
      candidates: [
        colorScheme.onSurface,
        colorScheme.onSurfaceVariant,
        Colors.black,
      ],
    );
    final children = <Widget>[
      if (accountProfile.distanceMeters != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _distanceLabelFromMeters(accountProfile.distanceMeters!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      if (accountProfile.tags.isNotEmpty)
        LayoutBuilder(
          builder: (context, constraints) {
            final maxChipWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 32;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accountProfile.tags
                  .map(
                    (tag) => ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxChipWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: chipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          tag.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: chipForeground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      if (_controller.canUseAsReferencePoint(accountProfile))
        _buildHeroReferencePointAction(accountProfile),
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

  Widget _buildHeroReferencePointAction(AccountProfileModel accountProfile) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = _controller.isCurrentReferencePoint(accountProfile);
    final backgroundColor = isCurrent
        ? colorScheme.secondaryContainer
        : colorScheme.primary;
    final foregroundColor = backgroundColor.computeIconColor(
      context,
      candidates: [
        isCurrent ? colorScheme.onSecondaryContainer : colorScheme.onPrimary,
        colorScheme.onSurface,
        Colors.white,
        Colors.black,
      ],
    );

    final currentButton = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('accountProfileHeroReferencePointButton'),
        onPressed: isCurrent
            ? () {}
            : () => unawaited(_handleReferencePointTap(accountProfile)),
        icon: Icon(
          isCurrent ? Icons.check_circle_rounded : Icons.location_on_outlined,
        ),
        label: Text(
          isCurrent ? 'Ponto de referência' : 'Usar como ponto de referência',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
    if (!isCurrent) {
      return currentButton;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        currentButton,
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('accountProfileHeroClearReferencePointButton'),
          onPressed: () => unawaited(_handleClearReferencePointTap()),
          icon: const Icon(Icons.location_off_outlined),
          label: const Text('Cancelar ponto de referência'),
        ),
      ],
    );
  }

  Future<void> _handleReferencePointTap(
    AccountProfileModel accountProfile,
  ) async {
    final confirmed = await _showReferencePointConfirmationDialog(
      accountProfile,
    );
    if (!mounted || !confirmed) {
      return;
    }
    try {
      final saved = await _controller.setAsReferencePoint(accountProfile);
      if (!mounted) {
        return;
      }
      _showStatusMessage(
        saved
            ? 'Ponto de referência atualizado.'
            : 'Não foi possível salvar o ponto de referência.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showStatusMessage('Não foi possível salvar o ponto de referência.');
    }
  }

  Future<void> _handleClearReferencePointTap() async {
    final confirmed = await _showClearReferencePointDialog();
    if (!mounted || !confirmed) {
      return;
    }
    try {
      final cleared = await _controller.clearReferencePoint();
      if (!mounted) {
        return;
      }
      _showStatusMessage(
        cleared
            ? 'Ponto de referência removido.'
            : 'Não foi possível remover o ponto de referência.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showStatusMessage('Não foi possível remover o ponto de referência.');
    }
  }

  Future<bool> _showReferencePointConfirmationDialog(
    AccountProfileModel accountProfile,
  ) async {
    final result = await showRouteScopedDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('accountProfileReferencePointDialog'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Todas as ',
                  children: [
                    const TextSpan(
                      text: 'distâncias',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: ' serão '),
                    const TextSpan(
                      text: 'calculadas',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: ' a partir desse local:'),
                  ],
                ),
                key: const Key('accountProfileReferencePointDialogCopy'),
                style: Theme.of(dialogContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildReferencePointPreviewCard(dialogContext, accountProfile),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('accountProfileReferencePointConfirmButton'),
                  onPressed: () => dialogContext.router.maybePop(true),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Usar como Ponto de Referência'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const Key('accountProfileReferencePointCancelButton'),
                  onPressed: () => dialogContext.router.maybePop(false),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _showClearReferencePointDialog() async {
    final result = await showRouteScopedDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('accountProfileClearReferencePointDialog'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancelar ponto de referência?',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'As distâncias voltarão a usar sua localização atual.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key(
                    'accountProfileClearReferencePointConfirmButton',
                  ),
                  onPressed: () => dialogContext.router.maybePop(true),
                  icon: const Icon(Icons.location_off_outlined),
                  label: const Text('Cancelar ponto de referência'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const Key('accountProfileClearReferencePointKeepButton'),
                  onPressed: () => dialogContext.router.maybePop(false),
                  child: const Text('Manter'),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Widget _buildReferencePointPreviewCard(
    BuildContext context,
    AccountProfileModel accountProfile,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedVisual = _controller.resolvedVisualFor(accountProfile);
    final typeLabel = _controller.typeLabelFor(accountProfile).trim();
    final address = accountProfile.locationAddress;
    final distanceLabel = accountProfile.distanceMeters == null
        ? null
        : _distanceLabelFromMeters(accountProfile.distanceMeters!);

    return Container(
      key: const Key('accountProfileReferencePointPreviewCard'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: AccountProfileIdentityBlock(
        name: accountProfile.name,
        avatarUrl: resolvedVisual.identityAvatarUrl,
        typeVisual: resolvedVisual.typeVisual,
        avatarSize: 44,
        avatarSpacing: 10,
        typeAvatarSize: 22,
        typeAvatarIconSize: 14,
        titleMaxLines: 1,
        titleStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        supportingSpacing: 8,
        supporting: _buildReferencePointPreviewSupporting(
          context,
          typeLabel: typeLabel,
          address: address,
          distanceLabel: distanceLabel,
        ),
      ),
    );
  }

  Widget? _buildReferencePointPreviewSupporting(
    BuildContext context, {
    required String typeLabel,
    required String? address,
    required String? distanceLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (typeLabel.isNotEmpty)
        Text(
          typeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (address != null)
        _buildReferencePointPreviewMetaRow(
          context,
          icon: Icons.place_outlined,
          label: address,
        )
      else if (distanceLabel != null)
        _buildReferencePointPreviewMetaRow(
          context,
          icon: Icons.place_outlined,
          label: distanceLabel,
        ),
    ];

    if (rows.isEmpty) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          rows[index],
        ],
      ],
    );
  }

  Widget _buildReferencePointPreviewMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  List<ImmersiveTabItem> _buildTabsFromConfig(
    AccountProfileModel accountProfile,
    PartnerProfileConfig config,
    Map<ProfileModuleId, Object?> moduleData,
  ) {
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
        .map((tab) => _buildConfiguredTab(tab, moduleData))
        .toList();

    tabs.sort(
      (left, right) =>
          _tabOrderRank(left.title).compareTo(_tabOrderRank(right.title)),
    );
    if (_controller.shouldRenderContactTab(accountProfile)) {
      tabs.add(_buildContactTab(accountProfile));
    }
    tabs.addAll(_buildNestedProfileGroupTabs(accountProfile));

    return tabs;
  }

  ImmersiveTabItem _buildConfiguredTab(
    ProfileTabConfig tab,
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    final content = _buildModules(tab.modules, moduleData);
    final normalizedTitle = tab.title.trim().toLowerCase();

    if (normalizedTitle == ImmersiveCommonTabs.aboutTitle.toLowerCase()) {
      return ImmersiveCommonTabs.about(content: content);
    }
    if (normalizedTitle.contains('chegar')) {
      return ImmersiveCommonTabs.directions(content: content);
    }

    return ImmersiveCommonTabs.custom(title: tab.title, content: content);
  }

  List<ImmersiveTabItem> _buildNestedProfileGroupTabs(
    AccountProfileModel accountProfile,
  ) {
    final groups =
        accountProfile.nestedProfileGroups
            .where((group) => group.isVisible)
            .toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order));

    return groups
        .map(
          (group) => ImmersiveTabItem(
            title: group.label,
            content: _nestedProfileGroup(group),
            footer: null,
          ),
        )
        .toList(growable: false);
  }

  int _tabOrderRank(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized == 'sobre') {
      return 0;
    }
    if (normalized == 'fale conosco') {
      return 1;
    }
    if (normalized == 'agenda' || normalized == 'eventos') {
      return 2;
    }
    if (normalized.contains('chegar')) {
      return 3;
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
    );
  }

  ImmersiveTabItem _buildContactTab(AccountProfileModel accountProfile) {
    final channels = _controller.availableContactChannelsFor(accountProfile);
    return ImmersiveTabItem(
      title: 'Contato',
      content: _buildContactTabContent(accountProfile, channels),
    );
  }

  Widget _buildContactTabContent(
    AccountProfileModel accountProfile,
    List<BellugaContactChannel> channels,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accountProfile.contactMode ==
              BellugaContactSourceMode.mirroredAccountProfile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                accountProfile.effectiveContactSourceProfile == null
                    ? 'Os canais deste perfil são atendidos por outro perfil do mesmo tenant.'
                    : 'Os canais deste perfil são atendidos por ${accountProfile.effectiveContactSourceProfile!.displayName}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          if (accountProfile.contactMode ==
              BellugaContactSourceMode.mirroredAccountProfile)
            const SizedBox(height: 16),
          for (var index = 0; index < channels.length; index++) ...[
            _buildContactChannelCard(accountProfile, channels[index]),
            if (index < channels.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildContactChannelCard(
    AccountProfileModel accountProfile,
    BellugaContactChannel channel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = switch (channel.iconToken) {
      BellugaContactIconToken.whatsapp => const Color(0xFF25D366),
      BellugaContactIconToken.emailOutlined => colorScheme.primary,
    };
    final title = channel.title?.trim().isNotEmpty == true
        ? channel.title!.trim()
        : channel.definition.canonicalLabel;
    return InkWell(
      key: Key('accountProfileContactChannelCard_${channel.id}'),
      borderRadius: BorderRadius.circular(24),
      onTap: () => unawaited(
        _invokeContactChannel(accountProfile, channel, origin: 'tab'),
      ),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_contactIconFor(channel.iconToken), color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildContactBubbleFloatingActionButton(
    AccountProfileModel accountProfile,
  ) {
    final bubbleChannel = _controller.resolvedBubbleChannelFor(accountProfile);
    if (bubbleChannel == null) {
      return null;
    }

    return VisibilityDetector(
      key: Key('accountProfileContactBubbleVisibility_${bubbleChannel.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _controller.trackContactBubbleImpression(accountProfile);
        }
      },
      child: FloatingActionButton(
        key: const Key('accountProfileContactBubbleButton'),
        heroTag:
            'accountProfileContactBubble_${accountProfile.id}_${bubbleChannel.id}',
        onPressed: () =>
            unawaited(_handleContactBubbleTap(accountProfile, bubbleChannel)),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        child: Icon(_contactIconFor(bubbleChannel.iconToken)),
      ),
    );
  }

  IconData _contactIconFor(BellugaContactIconToken token) {
    return switch (token) {
      BellugaContactIconToken.emailOutlined => Icons.email_outlined,
      BellugaContactIconToken.whatsapp => BooraIcons.whatsapp,
    };
  }

  void _checkPendingIntent() {
    if (widget.isWebRuntime) {
      return;
    }
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
    final result = _controller.toggleFavorite(accountProfileId);
    if (result != AccountProfileFavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    unawaited(
      AccountProfileFavoriteAuthGate.handleRequiredAuthentication(
        context: context,
        accountProfileId: accountProfileId,
        redirectPath: redirectPath,
        isWebRuntime: widget.isWebRuntime,
      ),
    );
  }

  Future<void> _handleContactBubbleTap(
    AccountProfileModel accountProfile,
    BellugaContactChannel bubbleChannel,
  ) async {
    _controller.trackContactBubbleTap(accountProfile);
    await _invokeContactChannel(
      accountProfile,
      bubbleChannel,
      origin: 'bubble',
    );
  }

  Future<void> _invokeContactChannel(
    AccountProfileModel accountProfile,
    BellugaContactChannel channel, {
    required String origin,
  }) async {
    if (channel.definition.capabilities.messagePresets &&
        channel.hasInitialMessages) {
      _controller.trackContactChooserOpen(
        accountProfile,
        channel: channel,
        origin: origin,
      );
      await _showContactChooserSheet(accountProfile, channel, origin: origin);
      return;
    }

    await _launchContactChannel(accountProfile, channel, origin: origin);
  }

  Future<void> _handleContactCtaTap(
    AccountProfileModel accountProfile,
    BellugaContactChannel channel,
    BellugaContactInitialMessage initialMessage, {
    required String origin,
  }) async {
    _controller.trackContactCtaTap(
      accountProfile,
      channel: channel,
      initialMessage: initialMessage,
      origin: origin,
    );
    await _launchContactChannel(
      accountProfile,
      channel,
      origin: origin,
      initialMessage: initialMessage,
      trackDirectClick: false,
    );
  }

  Future<void> _showContactChooserSheet(
    AccountProfileModel accountProfile,
    BellugaContactChannel channel, {
    required String origin,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var index = 0;
                  index < channel.initialMessages.length;
                  index++
                ) ...[
                  ListTile(
                    key: Key(
                      'accountProfileContactSheetCta_${channel.initialMessages[index].id}',
                    ),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_contactIconFor(channel.iconToken)),
                    title: Text(channel.initialMessages[index].cta),
                    onTap: () {
                      sheetContext.router.pop();
                      unawaited(
                        _handleContactCtaTap(
                          accountProfile,
                          channel,
                          channel.initialMessages[index],
                          origin: origin,
                        ),
                      );
                    },
                  ),
                  if (index < channel.initialMessages.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchContactChannel(
    AccountProfileModel accountProfile,
    BellugaContactChannel channel, {
    required String origin,
    BellugaContactInitialMessage? initialMessage,
    bool trackDirectClick = true,
  }) async {
    final resolution = _controller.resolveContactChannel(
      channel,
      initialMessage: initialMessage,
    );
    if (resolution == null) {
      _showStatusMessage('Canal de contato indisponível no momento.');
      return;
    }

    if (trackDirectClick && initialMessage == null) {
      _controller.trackContactDirectClick(
        accountProfile,
        channel: channel,
        origin: origin,
      );
    }

    try {
      final launcher = widget.externalUrlLauncher ?? _launchExternalUrl;
      final launched = await launcher(
        resolution.uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showStatusMessage('Não foi possível abrir o canal de contato.');
      }
    } catch (_) {
      if (mounted) {
        _showStatusMessage('Não foi possível abrir o canal de contato.');
      }
    }
  }

  Future<bool> _launchExternalUrl(Uri uri, {required LaunchMode mode}) {
    return launchUrl(uri, mode: mode);
  }

  Future<void> _shareAccountProfile(AccountProfileModel accountProfile) async {
    final payload = _buildAccountProfilePublicSharePayload(accountProfile);
    if (payload == null) {
      _showStatusMessage(
        'Não foi possível compartilhar ${accountProfile.name}.',
      );
      return;
    }

    try {
      await PublicShareLauncher.launchSystemShare(
        ShareParams(text: payload.message, subject: payload.subject),
        launcher: widget.shareLauncher,
      );
    } catch (_) {
      _showStatusMessage(
        'Não foi possível compartilhar ${accountProfile.name}.',
      );
    }
  }

  ({String subject, String message})? _buildAccountProfilePublicSharePayload(
    AccountProfileModel accountProfile,
  ) {
    if (!accountProfile.canOpenPublicDetail) {
      return null;
    }

    final publicDetailPath = accountProfile.publicDetailPath?.trim();
    if (publicDetailPath == null || publicDetailPath.isEmpty) {
      return null;
    }

    final publicUri = _controller.buildTenantPublicUriFromPath(
      publicDetailPath,
    );
    if (publicUri == null) {
      return null;
    }

    return AccountProfilePublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: accountProfile.name,
      profile: accountProfile,
      actorDisplayName: _controller.authenticatedUserDisplayName,
    );
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
    final foreground = onDarkBackground
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

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
    context.router.pushPath(path);
  }

  void _safeRouterPush(PageRouteInfo<dynamic> route) {
    context.router.push(route);
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

  Widget? _buildFavoriteFooterIfAvailable(
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
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.agendaScheduleLabel,
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
                              onError: (_, _) {},
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _buildAgendaLiveHighlightCard(accountProfile, featuredEvent),
            const SizedBox(height: 28),
          ],
          if (upcomingEvents.isNotEmpty) ...[
            Text(
              'Próximos Eventos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
    final distanceLabel = widget.accountProfile.distanceMeters == null
        ? null
        : _distanceLabelFromMeters(widget.accountProfile.distanceMeters!);
    final resolvedAddress = location?.address.trim();
    final hasAddress = resolvedAddress != null && resolvedAddress.isNotEmpty;
    final canOpenProfileMap = _canOpenProfileMap(location);
    final directionsTarget = _directionsTargetFromLocation(location);

    return ImmersiveDirectionsSection(
      padding: const EdgeInsets.all(16),
      mapCanvas: _buildLocationMapCanvas(location),
      destinationSubtitle: hasAddress ? resolvedAddress : null,
      distanceLabel: distanceLabel,
      canOpenMap: canOpenProfileMap,
      onOpenMap: canOpenProfileMap ? _openProfileMap : null,
      directionsTarget: directionsTarget,
      onOpenDirectDirections: _openDirectDirections,
      onOpenOtherDirections: _presentDirectionsTarget,
      mapTileKey: const Key('accountProfileLocationTile'),
      distanceBadgeKey: const Key('accountProfileLocationDistanceBadge'),
      primaryWazeButtonKey: const Key('accountProfileMainWazeButton'),
      primaryUberButtonKey: const Key('accountProfileMainUberButton'),
      primaryOtherButtonKey: const Key(
        'accountProfileMainOtherDirectionsButton',
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
                      BooraIcons.storeMallDirectory,
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
                BooraIcons.storeMallDirectory,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              address?.isNotEmpty == true ? address! : 'Mapa do local',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
      queryParameters: {'poi': 'account_profile:${widget.accountProfile.id}'},
    ).toString();
    _safeRouterPushPath(path);
  }

  Future<void> _openDirectDirections(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  ) async {
    final launched = await _directionsAppChooser.launchDirect(
      provider: provider,
      target: target,
    );
    if (!launched) {
      _showStatusMessage('Não foi possível abrir o aplicativo de rota.');
    }
  }

  Future<void> _presentDirectionsTarget(DirectionsLaunchTarget target) async {
    await _directionsAppChooser.present(
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

  Widget _buildFooterShell({required Widget child}) {
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
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          onTap: () => _safeRouterPush(
            ImmersiveEventDetailRoute(
              eventSlug: event.slug,
              occurrenceId: event.occurrenceId.trim().isEmpty
                  ? null
                  : event.occurrenceId.trim(),
            ),
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildAgendaImage(event),
              ),
              if (statusTint != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: statusTint),
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
                        'accountProfileAgendaLiveHeadline_${event.uniqueId}',
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                    ),
                    if (_agendaCounterparts(
                      accountProfile,
                      event,
                    ).isNotEmpty) ...[
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
                            event.expandedScheduleLabel,
                            style: Theme.of(context).textTheme.titleSmall
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
        metaLabel: event.agendaScheduleLabel,
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
      onTap: () => _safeRouterPush(
        // Keep upcoming and live agenda cards aligned on occurrence trimming.
        ImmersiveEventDetailRoute(
          eventSlug: event.slug,
          occurrenceId: () {
            final occurrenceId = event.occurrenceId.trim();
            return occurrenceId.isEmpty ? null : occurrenceId;
          }(),
        ),
      ),
      isConfirmed: _controller.isOccurrenceConfirmed(event.occurrenceId),
      pendingInvitesCount: _controller.pendingInviteCount(event.occurrenceId),
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
        child: Icon(Icons.event_outlined, color: colorScheme.onSurfaceVariant),
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
        _AgendaCounterpart(label: title, thumbUrl: counterpart.thumb),
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
    final visibleCounterparts = counterparts.length > 1
        ? counterparts.take(1).toList(growable: false)
        : counterparts;
    final hiddenCount = counterparts.length - visibleCounterparts.length;
    return Wrap(
      key: Key('${keyPrefix}_${event.uniqueId}'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleCounterparts.asMap().entries.map(
          (entry) => _buildAgendaCounterpartBadge(
            entry.value,
            labelStyle: textStyle,
            iconColor: iconColor,
            chipBackground: chipBackground,
            key: Key('$keyPrefix${entry.key}_${event.uniqueId}'),
          ),
        ),
        if (hiddenCount > 0)
          _buildAgendaCounterpartOverflowBadge(
            hiddenCount,
            labelStyle: textStyle,
            chipBackground: chipBackground,
            key: Key('${keyPrefix}More_${event.uniqueId}'),
          ),
      ],
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

  Widget _buildAgendaCounterpartOverflowBadge(
    int hiddenCount, {
    required TextStyle? labelStyle,
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
      child: Text(
        'e mais $hiddenCount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: labelStyle?.copyWith(fontWeight: FontWeight.w800),
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
          errorWidget: Icon(fallbackIcon, size: 16, color: iconColor),
        ),
      );
    }

    return Icon(fallbackIcon, size: 16, color: iconColor);
  }

  Color? _agendaStatusTint({
    required ColorScheme colorScheme,
    required PartnerEventView event,
  }) {
    if (_controller.isOccurrenceConfirmed(event.occurrenceId)) {
      return colorScheme.primary.withValues(alpha: 0.08);
    }
    if (_controller.pendingInviteCount(event.occurrenceId) > 0) {
      return colorScheme.secondary.withValues(alpha: 0.08);
    }
    return null;
  }

  Widget? _buildAgendaStatusWidget({
    required PartnerEventView event,
    required Color backgroundColor,
    required double size,
  }) {
    final isConfirmed = _controller.isOccurrenceConfirmed(event.occurrenceId);
    final pendingInvitesCount = _controller.pendingInviteCount(
      event.occurrenceId,
    );
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
                                onError: (_, _) {},
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
                          l.icon == 'pix' ? Icons.pix : Icons.link_outlined,
                        ),
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
                            onError: (_, _) {},
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _groupedPhotoGallery(List<AccountProfileGalleryGroup>? groups) {
    if (groups == null || groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const Key('accountProfileGroupedGallery'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (
            var groupIndex = 0;
            groupIndex < groups.length;
            groupIndex++
          ) ...[
            if (groupIndex > 0) const SizedBox(height: 24),
            Text(
              groups[groupIndex].subtitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
              ),
              itemCount: groups[groupIndex].items.length,
              itemBuilder: (context, itemIndex) {
                final item = groups[groupIndex].items[itemIndex];
                return Material(
                  color: Colors.transparent,
                  child: Semantics(
                    container: true,
                    button: true,
                    label: _galleryItemSemanticLabel(
                      group: groups[groupIndex],
                      item: item,
                    ),
                    child: InkWell(
                      key: Key('accountProfileGalleryItem_${item.itemId}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openGalleryItemModal(
                        group: groups[groupIndex],
                        item: item,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        child: BellugaNetworkImage(
                          item.previewUrl,
                          fit: BoxFit.cover,
                          clipBorderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGalleryItemModal({
    required AccountProfileGalleryGroup group,
    required AccountProfileGalleryItem item,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final viewport = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          key: Key('accountProfileGalleryModal_${item.itemId}'),
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: viewport.height - 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: InteractiveViewer(
                          child: BellugaNetworkImage(
                            item.modalUrl,
                            fit: BoxFit.contain,
                            placeholder: Container(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          onPressed: () => dialogContext.router.maybePop(),
                          tooltip: 'Fechar galeria',
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.subtitle,
                          style: Theme.of(dialogContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (item.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.description!.trim(),
                            key: Key(
                              'accountProfileGalleryModalDescription_${item.itemId}',
                            ),
                            style: Theme.of(dialogContext).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _galleryItemSemanticLabel({
    required AccountProfileGalleryGroup group,
    required AccountProfileGalleryItem item,
  }) {
    final description = item.description?.trim();
    if (description != null && description.isNotEmpty) {
      return 'Abrir foto da galeria ${group.subtitle}: $description';
    }
    return 'Abrir foto da galeria ${group.subtitle}';
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
                separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                            fontSize: 11,
                            color: Colors.black54,
                          ),
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
    String title,
    List<PartnerSupportedEntityView>? data,
  ) {
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
                separatorBuilder: (_, _) => const SizedBox(width: 12),
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

  Widget _nestedProfileGroup(AccountProfileNestedGroup group) {
    return Padding(
      key: Key('accountProfileNestedGroup_${group.id}'),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 720 ? 3 : (width >= 460 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: columns == 1 ? 124 : 136,
            ),
            itemCount: group.profiles.length,
            itemBuilder: (context, index) {
              final member = group.profiles[index];
              return _nestedProfileMemberCard(group, member);
            },
          );
        },
      ),
    );
  }

  Widget _nestedProfileMemberCard(
    AccountProfileNestedGroup group,
    AccountProfileNestedGroupMember member,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberProfile = _profileFromNestedMember(member);
    final resolvedVisual = _controller.resolvedVisualFor(memberProfile);
    final memberPath = _nestedProfileMemberPath(member);
    final labels = member.tags
        .map((tag) => tag.value.trim())
        .where((label) => label.isNotEmpty)
        .take(2)
        .toList(growable: false);
    return Material(
      key: Key('accountProfileNestedCard_${group.id}_${member.id}'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: memberPath == null
            ? null
            : () => _safeRouterPushPath(memberPath),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AccountProfileIdentityBlock(
                  name: member.name,
                  avatarUrl: resolvedVisual.identityAvatarUrl,
                  typeVisual: resolvedVisual.typeVisual,
                  avatarSize: 48,
                  avatarSpacing: 10,
                  typeAvatarSize: 24,
                  typeAvatarIconSize: 14,
                  titleSpacing: 6,
                  titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  supporting: labels.isEmpty
                      ? null
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: labels
                              .map(
                                (label) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _contentColorForBackground(
                                            colorScheme.secondaryContainer,
                                          ),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ),
              if (memberPath != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _nestedProfileMemberPath(AccountProfileNestedGroupMember member) {
    if (!member.canOpenPublicDetail) {
      return null;
    }

    final publicDetailPath = member.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      return publicDetailPath;
    }
    return null;
  }

  AccountProfileModel _profileFromNestedMember(
    AccountProfileNestedGroupMember member,
  ) {
    return AccountProfileModel(
      idValue: member.idValue,
      nameValue: member.nameValue,
      slugValue: member.slugValue ?? (SlugValue()..parse(member.id)),
      profileTypeValue: member.profileTypeValue,
      avatarValue: member.avatarValue,
      coverValue: member.coverValue,
      tagValues: member.tags,
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
              child: Text('Oferecimento: ${sponsor ?? 'Parceiro local'}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _richTextBlock(String? title, String body) {
    return _richTextBlocks([
      AccountProfileRichTextBlock(title: title, html: body),
    ]);
  }

  Widget _richTextBlocks(List<AccountProfileRichTextBlock> blocks) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleBlocks = blocks
        .map(
          (block) => _VisibleRichTextBlock(
            title: block.title,
            raw: block.html.trim(),
            html: SafeRichHtml.canonicalize(block.html),
          ),
        )
        .where((block) => block.html.isNotEmpty)
        .toList(growable: false);

    if (visibleBlocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < visibleBlocks.length; index++) ...[
            if (index > 0) const SizedBox(height: 24),
            if (visibleBlocks[index].title != null &&
                visibleBlocks[index].title!.trim().isNotEmpty) ...[
              Text(
                visibleBlocks[index].title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (SafeRichHtml.looksLikeHtml(visibleBlocks[index].raw))
              Html(
                data: visibleBlocks[index].html,
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
                  'p': Style(margin: Margins.only(bottom: 12)),
                  'strong': Style(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  'br': Style(display: Display.block),
                },
              )
            else
              _plainRichTextBody(visibleBlocks[index].raw, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _plainRichTextBody(String body, ColorScheme colorScheme) {
    final normalized = body
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n+'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var paragraphIndex = 0;
          paragraphIndex < paragraphs.length;
          paragraphIndex++
        ) ...[
          if (paragraphIndex > 0) const SizedBox(height: 12),
          for (final line in paragraphs[paragraphIndex].split('\n'))
            if (line.trim().isNotEmpty)
              Text(
                line.trimRight(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
        ],
      ],
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
        return _artistHighlights(data is List<PartnerEventView> ? data : null);
      case ProfileModuleId.agendaList:
        return _agendaList(
          widget.accountProfile,
          data is List<PartnerEventView> ? data : null,
        );
      case ProfileModuleId.musicPlayer:
        return _musicPlayer(data is List<PartnerMediaView> ? data : null);
      case ProfileModuleId.productGrid:
        return _productGrid(data is List<PartnerProductView> ? data : null);
      case ProfileModuleId.photoGallery:
        if (data is List<AccountProfileGalleryGroup>) {
          return _groupedPhotoGallery(data);
        }
        return _photoGrid(data is List<PartnerMediaView> ? data : null);
      case ProfileModuleId.videoGallery:
        return _videoGallery(data is List<PartnerMediaView> ? data : null);
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
        if (data is List<AccountProfileRichTextBlock>) {
          return _richTextBlocks(data);
        }
        return data is String
            ? _richTextBlock(module.title, data)
            : const SizedBox.shrink();
      case ProfileModuleId.locationInfo:
        return _locationInfo(data as PartnerLocationView?);
      case ProfileModuleId.externalLinks:
        return _externalLinks(data is List<PartnerLinkView> ? data : null);
      case ProfileModuleId.faq:
        return _faqBlock(data is List<PartnerFaqView> ? data : null);
      case ProfileModuleId.sponsorBanner:
        return _sponsorBanner(data is String ? data : null);
    }
  }
}

class _AgendaCounterpart {
  const _AgendaCounterpart({required this.label, this.thumbUrl});

  final String label;
  final String? thumbUrl;
}

class _VisibleRichTextBlock {
  const _VisibleRichTextBlock({
    required this.raw,
    required this.html,
    this.title,
  });

  final String raw;
  final String html;
  final String? title;
}
